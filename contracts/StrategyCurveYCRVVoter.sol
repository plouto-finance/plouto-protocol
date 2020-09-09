// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
*/

interface SCYCRVVController {
  function vaults(address) external view returns (address);
  function rewards() external view returns (address);
}

interface SCYCRVVGauge {
  function deposit(uint) external;
  function balanceOf(address) external view returns (uint);
  function withdraw(uint) external;
}

interface SCYCRVVMintr {
  function mint(address) external;
}

interface SCYCRVVUniswapRouter {
  function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface ySCYCRVVERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
}

interface ISCYCRVVCurveFi {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from,
    int128 to,
    uint256 _from_amount,
    uint256 _min_to_amount
  ) external;
}

contract StrategyCurveYCRVVoter {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public want = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
  address constant public pool = address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
  address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
  address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for crv <> weth <> dai route

  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public ydai = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
  address constant public curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);

  uint public keepCRV = 1000;
  uint constant public keepCRVMax = 10000;

  uint public performanceFee = 500;
  uint constant public performanceMax = 10000;

  uint public withdrawalFee = 50;
  uint constant public withdrawalMax = 10000;

  address public governance;
  address public controller;

  constructor(address _controller) public {
    governance = tx.origin;
    controller = _controller;
  }

  function getName() external pure returns (string memory) {
    return "StrategyCurveYCRVVoter";
  }

  function setKeepCRV(uint _keepCRV) external {
    require(msg.sender == governance, "!governance");
    keepCRV = _keepCRV;
  }

  function setWithdrawalFee(uint _withdrawalFee) external {
    require(msg.sender == governance, "!governance");
    withdrawalFee = _withdrawalFee;
  }

  function setPerformanceFee(uint _performanceFee) external {
    require(msg.sender == governance, "!governance");
    performanceFee = _performanceFee;
  }

  function deposit() public {
    uint _want = IERC20(want).balanceOf(address(this));
    if (_want > 0) {
      IERC20(want).safeApprove(pool, 0);
      IERC20(want).safeApprove(pool, _want);
      SCYCRVVGauge(pool).deposit(_want);
    }
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    require(crv != address(_asset), "crv");
    require(ydai != address(_asset), "ydai");
    require(dai != address(_asset), "dai");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  // Withdraw partial funds, normally used with a vault withdrawal
  function withdraw(uint _amount) external {
    require(msg.sender == controller, "!controller");
    uint _balance = IERC20(want).balanceOf(address(this));
    if (_balance < _amount) {
      _amount = _withdrawSome(_amount.sub(_balance));
      _amount = _amount.add(_balance);
    }

    uint _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

    IERC20(want).safeTransfer(SCYCRVVController(controller).rewards(), _fee);
    address _vault = SCYCRVVController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = SCYCRVVController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    SCYCRVVGauge(pool).withdraw(SCYCRVVGauge(pool).balanceOf(address(this)));
  }

  function harvest() public {
    require(msg.sender == governance, "!authorized");
    SCYCRVVMintr(mintr).mint(pool);
    uint _crv = IERC20(crv).balanceOf(address(this));
    if (_crv > 0) {
      uint _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
      IERC20(crv).safeTransfer(SCYCRVVController(controller).rewards(), _keepCRV);
      _crv = _crv.sub(_keepCRV);

      IERC20(crv).safeApprove(uni, 0);
      IERC20(crv).safeApprove(uni, _crv);

      address[] memory path = new address[](3);
      path[0] = crv;
      path[1] = weth;
      path[2] = dai;

      SCYCRVVUniswapRouter(uni).swapExactTokensForTokens(_crv, uint(0), path, address(this), now.add(1800));
    }
    uint _dai = IERC20(dai).balanceOf(address(this));
    if (_dai > 0) {
      IERC20(dai).safeApprove(ydai, 0);
      IERC20(dai).safeApprove(ydai, _dai);
      ySCYCRVVERC20(ydai).deposit(_dai);
    }
    uint _ydai = IERC20(ydai).balanceOf(address(this));
    if (_ydai > 0) {
      IERC20(ydai).safeApprove(curve, 0);
      IERC20(ydai).safeApprove(curve, _ydai);
      ISCYCRVVCurveFi(curve).add_liquidity([_ydai, 0, 0, 0], 0);
    }
    uint _want = IERC20(want).balanceOf(address(this));
    if (_want > 0) {
      uint _fee = _want.mul(performanceFee).div(performanceMax);
      IERC20(want).safeTransfer(SCYCRVVController(controller).rewards(), _fee);
      deposit();
    }
  }

  function _withdrawSome(uint256 _amount) internal returns (uint) {
    SCYCRVVGauge(pool).withdraw(_amount);
    return _amount;
  }

  function balanceOfWant() public view returns (uint) {
    return IERC20(want).balanceOf(address(this));
  }

  function balanceOfPool() public view returns (uint) {
    return SCYCRVVGauge(pool).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint) {
    return balanceOfWant().add(balanceOfPool());
  }

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setController(address _controller) external {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }
}
