// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenSaleLocked.sol";

contract TokenSaleUnlocked is TokenSaleLocked {
    struct UnlockedTable {
        uint8 percent;
        uint8 month;
    }

    modifier checkUnlocked() {
        UnlockedTable
            memory firstMonthUnlockedTable = _firstMonthUnlockedTable();

        uint256 firstTimeLocked = _lockedBalancesFirstTime[msg.sender];

        require(
            block.timestamp >
                firstTimeLocked +
                    (firstMonthUnlockedTable.month * _daysInMonth),
            "TokenSale::unlocked: Unlocked is not active"
        );
        _;
    }

    function _firstMonthUnlockedTable()
        private
        view
        returns (UnlockedTable memory)
    {
        uint8 checkMinMonth = 0;
        uint8 checkMinMonthIndex = 0;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            if (
                checkMinMonth > _unlockedMonths[i] && _unlockedPercents[i] > 0
            ) {
                checkMinMonth = _unlockedMonths[i];
                checkMinMonthIndex = i;
            }
        }

        return
            UnlockedTable(_unlockedPercents[checkMinMonthIndex], checkMinMonth);
    }

    constructor(address _busd, address _lott) {
        LOTT = IERC20(_lott);
        BUSD = IERC20(_busd);
    }

    function _unlocked(uint256 _amount) internal {
        LOTT.transfer(msg.sender, _amount);
        lockedBalances[msg.sender] -= _amount;
        emit UnLocked(msg.sender, _amount);
    }

    function unlocked(uint256 _amount) external checkUnlocked {
        uint32 percent = _percentUnlocked();
        uint256 maxPosibilityUnlocked = (percent *
            _lockedBalances[msg.sender]) / 100;
        require(
            maxPosibilityUnlocked >= _amount,
            "TokenSale::unlocked: Amount more than max posibility unlocked"
        );
        require(
            (_lockedBalances[msg.sender] - lockedBalances[msg.sender]) +
                _amount <=
                maxPosibilityUnlocked,
            "TokenSale::unlocked: Amount more than posibility unlocked"
        );
        uint256 actualBalanceLOTT = LOTT.balanceOf(address(this));
        require(
            actualBalanceLOTT >= _amount,
            "TokenSale::unlocked: Contract does not have enough money to unlock"
        );
        _unlocked(_amount);
    }

    function _percentUnlocked() private view returns (uint8) {
        uint8 percent;
        uint8 maxPercent = 100;
        uint256 timeNow = block.timestamp;
        uint256 firstTimeLocked = _lockedBalancesFirstTime[msg.sender];
        UnlockedTable
            memory firstItemUnlockedTable = _firstMonthUnlockedTable();

        uint8 calcPercent = 0;
        bool checkLastMonth = false;
        uint8 lastPercent;
        uint8 lastMonth;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            uint8 unLockedMonth = _unlockedMonths[i];
            uint8 unLockedPercent = _unlockedPercents[i];
            if (
                unLockedPercent > 0 &&
                timeNow >
                firstTimeLocked + (firstItemUnlockedTable.month * _daysInMonth)
            ) {
                calcPercent += unLockedPercent;
                if (i == _unlockedMonths.length - 1) {
                    checkLastMonth = true;
                    lastPercent = unLockedPercent;
                    lastMonth = unLockedMonth;
                }
            }
        }

        if (checkLastMonth && calcPercent < maxPercent) {
            uint8 calcMissingMonth = maxPercent - calcPercent / lastPercent;
            for (uint8 i = 1; i <= calcMissingMonth; i++) {
                uint8 nextMonth = calcMissingMonth + i;
                if (timeNow > firstTimeLocked + (nextMonth * _daysInMonth)) {
                    calcPercent += lastPercent;
                }
            }
        }

        percent = calcPercent;

        return percent;
    }
}
