// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LPTokenWrapper {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public vote = IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function stake(uint256 amount) public {
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    vote.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public {
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    vote.safeTransfer(msg.sender, amount);
  }
}
