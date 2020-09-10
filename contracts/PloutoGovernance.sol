// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "./IRewardDistributionRecipient.sol";
import "./LPTokenWrapper.sol";

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: PLURewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

interface IExecutor {
  function execute(uint, uint, uint, uint) external;
}

contract PulotoGovernance is LPTokenWrapper, IRewardDistributionRecipient {
  /* Fee collection for any other token */

  function seize(IERC20 _token, uint amount) external {
    require(msg.sender == governance, "!governance");
    require(_token != plu, "reward");
    require(_token != lp, "lp");
    _token.safeTransfer(governance, amount);
  }

  /* Fees breaker, to protect withdraws if anything ever goes wrong */

  bool public breaker = false;

  function setBreaker(bool _breaker) external {
    require(msg.sender == governance, "!governance");
    breaker = _breaker;
  }

  uint public minimumBPTLP = 1000e18;

  function setMinimumBPTLP(uint _minimum) public {
    require(msg.sender == governance, "!governance");
    minimumBPTLP = _minimum;
  }

  /* Modifications for proposals */

  mapping(address => uint) public voteLock; // period that your sake it locked to keep it for voting

  struct Proposal {
    uint id;
    address proposer;
    mapping(address => uint) forVotes;
    mapping(address => uint) againstVotes;
    uint totalForVotes;
    uint totalAgainstVotes;
    uint start; // block start;
    uint end; // start + period
    address executor;
    string hash;
    uint totalVotesAvailable;
    uint quorum;
    uint quorumRequired;
    bool open;
  }

  mapping (uint => Proposal) public proposals;
  uint public proposalCount;
  uint public period = 17280; // voting period in blocks ~ 17280 3 days for 15s/block
  uint public lock = 17280; // vote lock in blocks ~ 17280 3 days for 15s/block
  uint public minimum = 1e18;
  uint public quorum = 2000;

  address public governance;

  constructor (address _bptlp, address _plu) public LPTokenWrapper(_plu) {
    governance = tx.origin;
    proposalCount = 0;
    bptlp = IERC20(_bptlp);
    plu = IERC20(_plu);
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setQuorum(uint _quorum) public {
    require(msg.sender == governance, "!governance");
    quorum = _quorum;
  }

  function setMinimum(uint _minimum) public {
    require(msg.sender == governance, "!governance");
    minimum = _minimum;
  }

  function setPeriod(uint _period) public {
    require(msg.sender == governance, "!governance");
    period = _period;
  }

  function setLock(uint _lock) public {
    require(msg.sender == governance, "!governance");
    lock = _lock;
  }

  event NewProposal(uint id, address creator, uint start, uint duration, address executor);
  event Vote(uint indexed id, address indexed voter, bool vote, uint weight);

  function propose(address executor, string memory hash) public {
    require(votesOf(msg.sender) > minimum, "<minimum");
    proposals[proposalCount++] = Proposal({
      id: proposalCount,
      proposer: msg.sender,
      totalForVotes: 0,
      totalAgainstVotes: 0,
      start: block.number,
      end: period.add(block.number),
      executor: executor,
      hash: hash,
      totalVotesAvailable: totalVotes,
      quorum: 0,
      quorumRequired: quorum,
      open: true
    });

    emit NewProposal(proposalCount, msg.sender, block.number, period, executor);
    voteLock[msg.sender] = lock.add(block.number);
  }

  function execute(uint id) public {
    (uint _for, uint _against, uint _quorum) = getStats(id);
    require(proposals[id].quorumRequired < _quorum, "!quorum");
    require(proposals[id].end < block.number , "!end");
    if (proposals[id].open == true) {
      tallyVotes(id);
    }
    IExecutor(proposals[id].executor).execute(id, _for, _against, _quorum);
  }

  function getStats(uint id) public view returns (uint _for, uint _against, uint _quorum) {
    _for = proposals[id].totalForVotes;
    _against = proposals[id].totalAgainstVotes;

    uint _total = _for.add(_against);
    _for = _for.mul(10000).div(_total);
    _against = _against.mul(10000).div(_total);

    _quorum = _total.mul(10000).div(proposals[id].totalVotesAvailable);
  }

  event ProposalFinished(uint indexed id, uint _for, uint _against, bool quorumReached);

  function tallyVotes(uint id) public {
    require(proposals[id].open == true, "!open");
    require(proposals[id].end < block.number, "!end");

    (uint _for, uint _against,) = getStats(id);
    bool _quorum = false;
    if (proposals[id].quorum >= proposals[id].quorumRequired) {
      _quorum = true;
    }
    proposals[id].open = false;
    emit ProposalFinished(id, _for, _against, _quorum);
  }

  function votesOf(address voter) public view returns (uint) {
    return votes[voter];
  }

  uint public totalVotes;
  mapping(address => uint) public votes;
  event RegisterVoter(address voter, uint votes, uint totalVotes);
  event RevokeVoter(address voter, uint votes, uint totalVotes);

  function register() public {
    require(voters[msg.sender] == false, "voter");
    voters[msg.sender] = true;
    votes[msg.sender] = balanceOf(msg.sender);
    totalVotes = totalVotes.add(votes[msg.sender]);
    emit RegisterVoter(msg.sender, votes[msg.sender], totalVotes);
  }

  function revoke() public {
    require(voters[msg.sender] == true, "!voter");
    voters[msg.sender] = false;
    if (totalVotes < votes[msg.sender]) {
      // edge case, should be impossible, but this is defi
      totalVotes = 0;
    } else {
      totalVotes = totalVotes.sub(votes[msg.sender]);
    }
    emit RevokeVoter(msg.sender, votes[msg.sender], totalVotes);
    votes[msg.sender] = 0;
  }

  mapping(address => bool) public voters;

  function voteFor(uint id) public {
    require(proposals[id].start < block.number , "<start");
    require(proposals[id].end > block.number , ">end");

    uint _against = proposals[id].againstVotes[msg.sender];
    if (_against > 0) {
      proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.sub(_against);
      proposals[id].againstVotes[msg.sender] = 0;
    }

    uint vote = votesOf(msg.sender).sub(proposals[id].forVotes[msg.sender]);
    proposals[id].totalForVotes = proposals[id].totalForVotes.add(vote);
    proposals[id].forVotes[msg.sender] = votesOf(msg.sender);

    proposals[id].totalVotesAvailable = totalVotes;
    uint _votes = proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes);
    proposals[id].quorum = _votes.mul(10000).div(totalVotes);

    voteLock[msg.sender] = lock.add(block.number);

    emit Vote(id, msg.sender, true, vote);
  }

  function voteAgainst(uint id) public {
    require(proposals[id].start < block.number , "<start");
    require(proposals[id].end > block.number , ">end");

    uint _for = proposals[id].forVotes[msg.sender];
    if (_for > 0) {
      proposals[id].totalForVotes = proposals[id].totalForVotes.sub(_for);
      proposals[id].forVotes[msg.sender] = 0;
    }

    uint vote = votesOf(msg.sender).sub(proposals[id].againstVotes[msg.sender]);
    proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(vote);
    proposals[id].againstVotes[msg.sender] = votesOf(msg.sender);

    proposals[id].totalVotesAvailable = totalVotes;
    uint _votes = proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes);
    proposals[id].quorum = _votes.mul(10000).div(totalVotes);

    voteLock[msg.sender] = lock.add(block.number);

    emit Vote(id, msg.sender, false, vote);
  }

  /* Default rewards contract */

  IERC20 public bptlp;
  IERC20 public plu;

  uint256 public constant DURATION = 60 days;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  // stake visibility is public as overriding LPTokenWrapper's stake() function
  function stake(uint256 amount) public updateReward(msg.sender) {
    require(amount > 0, "Cannot stake 0");
    if (breaker == false) {
      require(bptlp.balanceOf(msg.sender) > minimumBPTLP, "<minimumBPTLP");
      require(voteLock[msg.sender] > block.number, "<block.number");
    }
    if (voters[msg.sender] == true) {
      votes[msg.sender] = votes[msg.sender].add(amount);
      totalVotes = totalVotes.add(amount);
    }
    super.stake(amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    if (voters[msg.sender] == true) {
      votes[msg.sender] = votes[msg.sender].sub(amount);
      totalVotes = totalVotes.sub(amount);
    }
    if (breaker == false) {
      require(voteLock[msg.sender] < block.number,"!locked");
    }
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward() public updateReward(msg.sender) {
    if (breaker == false) {
      require(bptlp.balanceOf(msg.sender) > minimum, "<minimum");
      require(voteLock[msg.sender] > block.number,"!voted");
    }
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      plu.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function notifyRewardAmount(uint256 reward) external onlyRewardDistribution updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }
}
