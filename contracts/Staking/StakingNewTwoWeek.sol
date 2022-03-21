// SPDX-License-Identifier: MIT
// NIFTSY protocol for StakedContract
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/address.sol";

contract StakedContract is Ownable {
    using Address for address;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);
    event WithdrawaStake(address indexed user, uint256 amount, uint256 reward, uint256 index, uint256 timestamp);
    event ApproveStake(address indexed user, uint256 index, uint256 timestamp);
    event UnStake(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    IERC20 LOTT;
    uint256 public minimumNumberLOTTtoStaking = 0;
    uint256 minimumNumberLOTTtoWithdrawal = 0;

    struct StakesData {
        uint256 index;
        bool isExist;
    }

    struct StakingSummaryForAdmin{
        address staker;
        Stake[] stakes;
    }

    struct StakingSummary{
        uint256 totalAmount;
        Stake[] stakes;
    }

    struct StakeholdersSummary{
        address[] stakers;
        Stake[][] stakes;
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 dailyPercentage;
        uint256 periodPercentage;
        uint256 timestamp;
        uint64 period;
        uint256 unlockTime;
        uint256 claimable;
        bool approve;
        bool paidOut;
        uint256 index;
    }

    struct Stakeholder {
        address user;
        Stake[] addressStakes;
    }

    Stakeholder[] internal stakeholders;

    mapping(address => StakesData) internal stakes;
    mapping(address => uint256) internal _balances;

    modifier checkPeriod(uint64 _period) {
        require(_period == 14, "Staking:: Unavailable period for staking");
        _;
    }

    modifier checkMaxDepositByPeriod(uint256 _amount, uint64 _period) {
        if (_period == 14) {
            require(_amount <= 1000 * (10**18), "Staking:: Max deposit 1000 LOTT");
        }
        _;
    }

    modifier checkAvailableStaking(uint256 _amount, uint64 _period) {
        StakesData memory stakesData = stakes[msg.sender];

        if (stakesData.isExist) {
            StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[msg.sender].index].addressStakes);
            if (summary.stakes.length > 0) {
                for (uint256 s = 0; s < summary.stakes.length; s += 1) {
                    if (summary.stakes[s].period == _period) {
                        require(summary.stakes[s].paidOut, "Staking:: You have active staking for this period");
                    }
                }
            }
        }
        _;
    }

    constructor(address _address) {
        require(
           _address.isContract(),
           "Staking::setLottContractAddress: Address must be contract address"
        );
        LOTT = IERC20(_address);
    }

    function balanceOf() public view returns(uint256) {
        return _balances[msg.sender];
    }

    function stake(uint256 _amount, uint64 _period) external checkPeriod(_period) checkMaxDepositByPeriod(_amount, _period) checkAvailableStaking(_amount, _period) {
        require(_amount > 0 && _amount >= minimumNumberLOTTtoStaking, "Staking::stake: Unavailable number of LOTTS for stake");
        _gettingSteakingToken(_amount);
        _stake(_amount, _period);
    }

    function getSteakingWallets() external view onlyOwner returns (address[] memory, uint256[] memory) {
        address[] memory userWallets = new address[](stakeholders.length);
        uint256[] memory userBalances = new uint256[](stakeholders.length);

        for (uint256 i = 0; i < stakeholders.length; i++) {
            address item = stakeholders[i].user;
            uint256 balance = _balances[item];
            userWallets[i] = item;
            userBalances[i] = balance;
        }

        return (userWallets, userBalances);
    }

    function setLottContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "Staking::setLottContractAddress: Address must be contract address"
        );
        LOTT = IERC20(_address);
    }

    function setMinimumNumberLOTTtoStaking(uint256 _amount) external onlyOwner {
        require(_amount >= 0, "Staking::setMinimumNumberLOTTtoStaking: _amount cannot be lower than 0");
        minimumNumberLOTTtoStaking = _amount;
    }

    function setMinimumNumberLOTTtoWithdrawal(uint256 _amount) external onlyOwner {
        require(_amount >= 0, "Staking::setMinimumNumberLOTTtoWithdrawal: _amount cannot be lower than 0");
        minimumNumberLOTTtoWithdrawal = _amount;
    }

    function calculateStakeReward() external view onlyOwner returns (Stake[][] memory) {
        Stake[][] memory addressStakes = new Stake[][](stakeholders.length);

        uint256 addressStakesIndex = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            Stake[] memory _stakes = stakeholders[s].addressStakes;
            Stake[] memory appropriateStakes = new Stake[](_stakes.length);
            uint256 appStakeIndex = 0;
            for (uint256 st = 0; st < _stakes.length; st += 1) {
                if (_stakes.length > 0) {
                    Stake memory _currentStake = _stakes[st];

                    if (block.timestamp > _currentStake.unlockTime && !_currentStake.paidOut && _currentStake.approve) {
                        uint256 availableReward = _calculateStakeRewardForPeriod(_currentStake);
                        _currentStake.claimable = availableReward;
                        appropriateStakes[appStakeIndex] = _currentStake;
                        appStakeIndex += 1;
                    }
                }
            }

            if (appropriateStakes.length > 0 && appropriateStakes[0].amount > 0) {
                addressStakes[addressStakesIndex] = appropriateStakes;
                addressStakesIndex += 1;
            }
        }

        return addressStakes;
    }

    function ownStake() external view returns(StakingSummary memory){
        require(stakes[msg.sender].isExist, "Staking::ownStake: Stake not found");
        uint256 totalStakeAmount;

        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[msg.sender].index].addressStakes);

        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = 0;
            if (summary.stakes[s].unlockTime > block.timestamp) {
                availableReward = _calculateStakeReward(summary.stakes[s]);
            } else {
                availableReward = _calculateStakeRewardForPeriod(summary.stakes[s]);
            }

           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }

        summary.totalAmount = totalStakeAmount;
        return summary;
    }

    function hasStake(address _staker) external view onlyOwner returns(StakingSummary memory){
        require(stakes[_staker].isExist, "Staking::ownStake: Stake not found");
        uint256 totalStakeAmount;

        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker].index].addressStakes);

        for (uint256 s = 0; s < summary.stakes.length; s += 1){
            uint256 availableReward = 0;
            if (summary.stakes[s].unlockTime > block.timestamp) {
                availableReward = _calculateStakeReward(summary.stakes[s]);
            } else {
                availableReward = _calculateStakeRewardForPeriod(summary.stakes[s]);
            }
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }

        summary.totalAmount = totalStakeAmount;
        return summary;
    }

    function approveStake(address staker, uint256 stakeIndex) external onlyOwner {
        _approveStake(staker, stakeIndex);
    }

    function getStakeholders() external view onlyOwner returns(StakeholdersSummary memory) {
        address[] memory stakers = new address[](stakeholders.length);
        Stake[][] memory addressStakes = new Stake[][](stakeholders.length);
        uint256 userIndex = 0;
        uint256 stakesIndex = 0;

        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            uint256 stakeholdersLength = stakeholders[s].addressStakes.length;

            if (stakeholdersLength > 0) {
                Stake[] memory appropriateStakes = new Stake[](stakeholdersLength);
                stakesIndex = 0;

                for (uint256 st = 0; st < stakeholders[s].addressStakes.length; st += 1) {
                    Stake memory currentStake = stakeholders[s].addressStakes[st];
                    if (currentStake.unlockTime - 1 days < block.timestamp && !currentStake.approve && !currentStake.paidOut) {
                        uint256 availableReward = _calculateStakeRewardForPeriod(currentStake);
                        currentStake.claimable = availableReward;
                        appropriateStakes[stakesIndex] = currentStake;
                        stakesIndex += 1;
                    }
                }

                if (appropriateStakes.length > 0 && appropriateStakes[0].amount != 0) {
                    stakers[userIndex] = stakeholders[s].user;
                    addressStakes[userIndex] = appropriateStakes;
                    userIndex++;
                }
            }
        }
        StakeholdersSummary memory summary =  StakeholdersSummary(stakers, addressStakes);
        return summary;
    }

    function _gettingSteakingToken(uint256 _amount) internal {
        require(
            LOTT.allowance(msg.sender, address(this)) >= _amount,
            "Allowance too low"
        );

        require(
            LOTT.transferFrom(
                msg.sender,
                address(this),
                _amount
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );

        _balances[msg.sender] += _amount;
    }

    function _addStakeholder(address staker) internal returns (uint256){
        stakeholders.push(); // Make space for our new stakeholder
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker].index = userIndex;
        stakes[staker].isExist = true;

        return userIndex;
    }

    function _stake(uint256 _amount, uint64 _period) internal {
        uint256 index;

        StakesData memory stakesData = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if (!stakesData.isExist) {
            index = _addStakeholder(msg.sender);
        } else {
            index = stakesData.index;
        }

        uint256 lastIndexNumber = stakeholders[index].addressStakes.length;

        uint256 unlockTime = _calculateUnlockTime(_period);
        stakeholders[index].addressStakes.push(Stake(msg.sender, _amount, _calculateRewardPrecent(_period), _calculateRewardPrecentForPeriod(_period), timestamp, _period, unlockTime, 0, false, false, lastIndexNumber));

        emit Staked(msg.sender, _amount, index, timestamp);
    }

    function _calculateUnlockTime(uint64 _period) internal view returns(uint256) {
        uint256 unlockTime;
        if (_period == 14) unlockTime = block.timestamp + 14 days;

        return unlockTime;
    }

    function _calculateRewardPrecent(uint64 _period) internal pure returns(uint256) {
        uint256 _precent = 0;
        if (_period == 14) _precent = 280555555555555560;

        return _precent;
    }

    function _calculateRewardPrecentForPeriod(uint64 _period) internal pure returns(uint256) {
        uint256 _precent = 0;
        if (_period == 14) _precent = 101000000000000000000;

        return _precent;
    }

    function _percentageFromNumber(uint256 _number, uint256 _precent) internal pure returns(uint256) {
        return _number * _precent / 100;
    }

    function _calculateStakeReward(Stake memory _currentStake) internal view returns(uint256) {
        uint256 _precent = _currentStake.dailyPercentage;
        uint256 diffDays = (block.timestamp - _currentStake.timestamp) / 1 days;
        return (diffDays * (_percentageFromNumber(_currentStake.amount, _precent))) / (10 ** 18);
    }

    function _calculateStakeRewardForPeriod(Stake memory _currentStake) internal pure returns(uint256) {
        uint256 _precent = _currentStake.periodPercentage;
        uint256 periodsInOneYear = 360 / _currentStake.period;
        return (_percentageFromNumber(_currentStake.amount, _precent) / periodsInOneYear) / (10 ** 18);
    }

    function withdrawalStake(address receiver, uint256 index) external onlyOwner {
        uint256 userIndex = stakes[receiver].index;
        Stake memory currentStake = stakeholders[userIndex].addressStakes[index];
        uint256 amount = currentStake.amount;

        uint256 reward = _calculateStakeRewardForPeriod(currentStake);
        require(currentStake.paidOut == false && currentStake.approve == true, "Staking::Unstake: This staking has already been paid");
        require(reward >= minimumNumberLOTTtoWithdrawal, "Staking::withdrawStake: reward less than minimumNumberLOTTtoWithdrawal");


        stakeholders[userIndex].addressStakes[index].paidOut = true;
        _balances[receiver] -= amount;

        LOTT.transfer(receiver, amount + reward);
        emit WithdrawaStake(receiver, amount, reward, index, block.timestamp);
    }

    function unStake(uint256 index) external {
        uint256 userIndex = stakes[msg.sender].index;
        Stake memory currentStake = stakeholders[userIndex].addressStakes[index];
        require(currentStake.paidOut == false && currentStake.approve == false, "Staking::Unstake: This staking has already been paid");

        stakeholders[userIndex].addressStakes[index].paidOut = true;
        _balances[msg.sender] -= currentStake.amount;
        LOTT.transfer(msg.sender, currentStake.amount);
        emit UnStake(msg.sender, currentStake.amount, index, block.timestamp);
    }

    function unStakeForOwner(address receiver, uint256 index) external onlyOwner {
        uint256 userIndex = stakes[receiver].index;
        Stake memory currentStake = stakeholders[userIndex].addressStakes[index];
        require(currentStake.paidOut == false, "Staking::Unstake: This staking has already been paid");

        stakeholders[userIndex].addressStakes[index].paidOut = true;
        _balances[receiver] -= currentStake.amount;
        LOTT.transfer(receiver, currentStake.amount);
        emit UnStake(receiver, currentStake.amount, index, block.timestamp);
    }

    function _approveStake(address _staker, uint256 _stakeIndex) internal {
        Stake memory currentStake = stakeholders[stakes[_staker].index].addressStakes[_stakeIndex];
        require(!currentStake.approve, "Staking::approveStake: Stake already confirmed");

        stakeholders[stakes[_staker].index].addressStakes[_stakeIndex].approve = true;
        emit ApproveStake(_staker, _stakeIndex, block.timestamp);
    }
}