pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/address.sol";

contract StakedContract is Ownable {
    using Address for address;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    string constant defaultAuthLevel = "Default";
    string constant proAuthLevel = "Professional";
    string constant expertAuthLevel = "Expert";
    string constant partnerAuthLevel = "Partner";

    IERC20 LOTT;

    struct StakesData {
        uint256 index;
        bool isExist;
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    struct Stakeholder {
        address user;
        string authorizationLevel;
        Stake[] addressStakes;
    }

    Stakeholder[] internal stakeholders;

    mapping(address => StakesData) internal stakes;
    mapping(address => uint256) internal _balances;

    function balanceOf() public view returns(uint256) {
        return _balances[msg.sender];
    }

    function setLottContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "Staking::setLottContractAddress: Address must be contract address"
        );
        LOTT = IERC20(_address);
    }

    function _gettingSteakingToken(uint256 _amount) internal {
        require(
            LOTT.allowance(msg.sender, address(this)) >= _amount,
            "Staking::_gettingSteakingToken: Allowance too low"
        );

        require(
            LOTT.transferFrom(
                msg.sender,
                address(this),
                _amount
            ) == true,
            "Staking::_gettingSteakingToken: Could not transfer tokens from your address to this contract"
        );

        _balances[msg.sender] += _amount;
    }

    function getAuthLevel() external view returns(string memory) {
        StakesData memory stakesData = stakes[msg.sender];
        if (stakesData.isExist) {
            return stakeholders[stakesData.index].authorizationLevel;
        }
    }

    function _addStakeholder(address staker) internal returns (uint256){
        stakeholders.push(); // Make space for our new stakeholder
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker].index = userIndex;
        stakes[staker].isExist = true;

        return userIndex;
    }

    function _stake(uint256 _amount) internal {
        uint256 index;

        StakesData memory stakesData = stakes[msg.sender];
        uint256 timestamp = block.timestamp;

        if (!stakesData.isExist) {
            index = _addStakeholder(msg.sender);
        } else {
            index = stakesData.index;
        }

        stakeholders[index].addressStakes.push(Stake(msg.sender, _amount, timestamp));

        _updateStakeholderAuthLevel(index, _balances[msg.sender]);

        emit Staked(msg.sender, _amount, index,timestamp);
    }

    function _updateStakeholderAuthLevel(uint256 index, uint256 balance) internal {
        if (balance >= 1000 * (10 ** 18) && balance < 10000 * (10 ** 18)) {
            stakeholders[index].authorizationLevel = proAuthLevel;
        } else if (balance >= 10000 * (10 ** 18) && balance < 100000 * (10 ** 18)) {
            stakeholders[index].authorizationLevel = expertAuthLevel;
        } else if (balance >= 100000 * (10 ** 18)) {
            stakeholders[index].authorizationLevel = partnerAuthLevel;
        } else {
            stakeholders[index].authorizationLevel = defaultAuthLevel;
        }
    }

    function stake(uint256 _amount) external {
        _gettingSteakingToken(_amount);
        _stake(_amount);
    }

    function getSteakingWallets()
        external
        view
        onlyOwner
        returns (address[] memory, uint256[] memory)
    {
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
}