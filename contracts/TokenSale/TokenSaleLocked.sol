// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TokenSaleBase.sol";
import "../utils/safemath.sol";
import "../utils/address.sol";

contract TokenSaleLocked is TokenSaleBase {
    using SafeMath for uint256;
    using Address for address;

    struct LockedWallets {
        address owner;
        uint256 locked;
    }

    modifier validateLocked(uint256 _amountBUSD) {
        uint256 amoutLott = _amountBUSD.div(_lottPrice).mul(10**18);
        require(_startDate > 0 && block.timestamp > _startDate, "TokenSale::locked: Token Sale has not started yet");
        require(
            block.timestamp > _startDate && block.timestamp < _finishDate,
            "TokenSale::locked: TokenSale already finished"
        );
        require(
            _maxCap > 0 && _maxCap >= amoutLott,
            "TokenSale::locked: TokenSale already finished"
        );
        require(
            amoutLott > 0,
            "TokenSale::locked: Amount less than minimum purchase"
        );
        uint256 tokenSaleLottBalance = LOTT.balanceOf(address(this));
        require(
            tokenSaleLottBalance >= amoutLott,
            "TokenSale::locked: Amount more than token sale LOTT balance"
        );
        _;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return lockedBalances[_owner];
    }

    function setLottContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "TokenSale::setLottContractAddress: Address must be contract address"
        );
        LOTT = IERC20(_address);
    }

    function setBUSDContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "TokenSale::setBUSDContractAddress: Address must be contract address"
        );
        BUSD = IERC20(_address);
    }

    function _locked(address _to, uint256 _amountLOTT) private {
        _maxCap -= _amountLOTT;
        lockedBalances[_to] += _amountLOTT;
        _lockedBalances[_to] += _amountLOTT;
        _lockedWallets.push(_to);
        if (_lockedBalancesFirstTime[_to] == 0) {
            _lockedBalancesFirstTime[_to] = block.timestamp;
        }
        emit Locked(_to, _amountLOTT);
    }

    function _lockedForOwner(address _to, uint256 _amountLOTT) private {
        _locked(_to, _amountLOTT);
    }

    function locked(uint256 _amountBUSD) external validateLocked(_amountBUSD) {
        uint256 amoutLOTT = _amountBUSD.div(_lottPrice).mul(10**18);
        uint256 amountBUSD = amoutLOTT.mul(_lottPrice).div(10**18);
        BUSD.transferFrom(tx.origin, address(this), amountBUSD);
        _locked(tx.origin, amoutLOTT);
    }

    function lockedForOwner(address _to, uint256 _amountBUSD)
        external
        onlyOwnerOrigin
        validateLocked(_amountBUSD)
    {
        require(
            !_to.isContract(),
            "TokenSale::lockedForOwner: To address must not be contract address"
        );
        require(
            _to != address(0),
            "TokenSale::lockedForOwner: To address is zero."
        );
        uint256 amoutLott = _amountBUSD.div(_lottPrice).mul(10**18);
        _lockedForOwner(_to, amoutLott);
    }

    function getLockedWallets()
        external
        view
        onlyOwnerOrigin
        returns (address[] memory, uint256[] memory)
    {
        address[] memory userWallets = new address[](_lockedWallets.length);
        uint256[] memory userBalances = new uint256[](_lockedWallets.length);
        
        for (uint256 i = 0; i < _lockedWallets.length; i++) {
            address item = _lockedWallets[i];
            uint256 balance = lockedBalances[item];
            userWallets[i] = item;
            userBalances[i] = balance;
        }

        return (userWallets, userBalances);
    }
}
