// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./TokenSaleBase.sol";
import "../utils/address.sol";

contract TokenSaleLocked is TokenSaleBase {
    using Address for address;

    struct LockedWallets {
        address owner;
        uint256 locked;
    }

    modifier validateLocked(uint256 _amountBUSD) {
        uint256 amoutLott = calcul(_amountBUSD, _lottPrice, 18);
        require(
            (block.timestamp > _startDate && block.timestamp < _finishDate) || _maxCap >= amoutLott,
            "TokenSale::locked: TokenSale is not active"
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

    function calcul(uint a, uint b, uint precision) internal pure returns (uint) {
        return a*(10**precision)/b;
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
        uint256 amountLOTT = calcul(_amountBUSD, _lottPrice, 18);
        BUSD.transferFrom(msg.sender, address(this), _amountBUSD);
        _locked(msg.sender, amountLOTT);
    }

    function lockedForOwner(address _to, uint256 _amountBUSD)
        external
        onlyOwner
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
        uint256 amountLOTT = calcul(_amountBUSD, _lottPrice, 18);

        _lockedForOwner(_to, amountLOTT);
    }

    function getLockedWallets()
        external
        view
        onlyOwner
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory userBalances = new uint256[](_lockedWallets.length);
        
        for (uint256 i = 0; i < _lockedWallets.length; i++) {
            address item = _lockedWallets[i];
            uint256 balance = lockedBalances[item];
            userBalances[i] = balance;
        }

        return (_lockedWallets, userBalances);
    }
}
