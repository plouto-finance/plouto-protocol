// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface SCYFIController {
  function vaults(address) external view returns (address);
  function rewards() external view returns (address);
}

/*
 A strategy must implement the following calls;

 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()

 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
*/

interface SCYFIUniswapRouter {
  function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface SCYFICreamtroller {
  function claimComp(address holder) external;
}

interface cSCYFIToken {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function exchangeRateStored() external view returns (uint);
  function balanceOf(address _owner) external view returns (uint);
  function underlying() external view returns (address);
}

contract StrategyCreamYFI {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address constant public want = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);

  SCYFICreamtroller public constant creamtroller = SCYFICreamtroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

  address constant public crYFI = address(0xCbaE0A83f4f9926997c8339545fb8eE32eDc6b76);
  address constant public cream = address(0x2ba592F78dB6436527729929AAf6c908497cB200);

  address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for cream <> weth <> yfi route

  uint public performanceFee = 600;
  uint constant public performanceMax = 10000;

  address public governance;
  address public controller;

  constructor(address _controller) public {
    governance = tx.origin;
    controller = _controller;
  }

  function getName() external pure returns (string memory) {
    return "StrategyCreamYFI";
  }

  function setPerformanceFee(uint _performanceFee) external {
    require(msg.sender == governance, "!governance");
    performanceFee = _performanceFee;
  }

  function deposit() public {
    uint _want = IERC20(want).balanceOf(address(this));
    if (_want > 0) {
      IERC20(want).safeApprove(crYFI, 0);
      IERC20(want).safeApprove(crYFI, _want);
      cSCYFIToken(crYFI).mint(_want);
    }
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    require(crYFI != address(_asset), "crYFI");
    require(cream != address(_asset), "cream");
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

    address _vault = SCYFIController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount);
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint balance) {
    require(msg.sender == controller, "!controller");
    _withdrawAll();

    balance = IERC20(want).balanceOf(address(this));

    address _vault = SCYFIController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function _withdrawAll() internal {
    uint256 amount = balanceC();
    if (amount > 0) {
      _withdrawSome(balanceCInToken().sub(1));
    }
  }

  function harvest() public {
    require(msg.sender == governance, "!authorized");
    SCYFICreamtroller(creamtroller).claimComp(address(this));
    uint _cream = IERC20(cream).balanceOf(address(this));
    if (_cream > 0) {
      IERC20(cream).safeApprove(uni, 0);
      IERC20(cream).safeApprove(uni, _cream);

      address[] memory path = new address[](3);
      path[0] = cream;
      path[1] = weth;
      path[2] = want;

      SCYFIUniswapRouter(uni).swapExactTokensForTokens(_cream, uint(0), path, address(this), now.add(1800));
    }
    uint _want = IERC20(want).balanceOf(address(this));
    if (_want > 0) {
      uint _fee = _want.mul(performanceFee).div(performanceMax);
      IERC20(want).safeTransfer(SCYFIController(controller).rewards(), _fee);
      deposit();
    }
  }

  function _withdrawSome(uint256 _amount) internal returns (uint) {
    uint256 b = balanceC();
    uint256 bT = balanceCInToken();
    // can have unintentional rounding errors
    uint256 amount = (b.mul(_amount)).div(bT).add(1);
    uint _before = IERC20(want).balanceOf(address(this));
    _withdrawC(amount);
    uint _after = IERC20(want).balanceOf(address(this));
    uint _withdrew = _after.sub(_before);
    return _withdrew;
  }

  function balanceOfWant() public view returns (uint) {
    return IERC20(want).balanceOf(address(this));
  }

  function _withdrawC(uint amount) internal {
    cSCYFIToken(crYFI).redeem(amount);
  }

  function balanceCInToken() public view returns (uint256) {
    // Mantisa 1e18 to decimals
    uint256 b = balanceC();
    if (b > 0) {
      b = b.mul(cSCYFIToken(crYFI).exchangeRateStored()).div(1e18);
    }
    return b;
  }

  function balanceC() public view returns (uint256) {
    return IERC20(crYFI).balanceOf(address(this));
  }

  function balanceOf() public view returns (uint) {
    return balanceOfWant().add(balanceCInToken());
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
