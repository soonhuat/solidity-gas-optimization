// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract GasContract is Ownable {
    uint256 private paymentCounter = 0;
    uint256 public totalSupply = 1; // cannot be updated
    address[5] public administrators;
    mapping(address => uint256) private balances;
    mapping(address => Payment[]) private payments;
    mapping(address => uint256) public whitelist;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct ImportantStruct {
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
    }

    error Unauthorized();

    modifier onlyAdminOrOwner() {
        if (owner() == msg.sender || checkForAdmin(msg.sender)) {
            _;
        } else {
            revert Unauthorized();
        }
    }

    modifier checkIfWhiteListed() {
        require(
            whitelist[msg.sender] > 0,
            "Gas Contract CheckIfWhiteListed modifier : revert happened because the user is not whitelisted"
        );
        require(
            whitelist[msg.sender] < 4,
            "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
        );
        _;
    }

    event Transfer(address, uint256);

    constructor(address[5] memory _admins, uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;

        for (uint256 i = 0; i < 5; i++) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint256 i = 0; i < 5; i++) {
            if (administrators[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function getTradingMode() external pure returns (bool) {
        return true;
    }

    function getPayments(address _user)
        external
        view
        returns (Payment[] memory)
    {
        require(
            _user != address(0),
            "Gas Contract - getPayments function - User must have a valid non zero address"
        );
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "Gas Contract - Transfer function - Sender has insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "Gas Contract - Transfer function -  The recipient name is too long, there is a max length of 8 characters"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external onlyAdminOrOwner {
        require(
            _ID > 0,
            "Gas Contract - Update Payment function - ID must be greater than 0"
        );
        require(
            _amount > 0,
            "Gas Contract - Update Payment function - Amount must be greater than 0"
        );
        require(
            _user != address(0),
            "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
        );

        Payment[] storage userPayments = payments[_user];
        for (uint256 i = 0; i < userPayments.length; i++) {
            if (userPayments[i].paymentID == _ID) {
                userPayments[i].adminUpdated = true;
                userPayments[i].admin = _user;
                userPayments[i].paymentType = _type;
                userPayments[i].amount = _amount;
                break;
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        external
        onlyAdminOrOwner
    {
        require(
            _tier < 255,
            "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
        );
        whitelist[_userAddrs] = (_tier > 3) ? 3 : _tier;
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount,
        ImportantStruct calldata
    ) external checkIfWhiteListed() {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
        );
        balances[senderOfTx] -= _amount - whitelist[senderOfTx];
        balances[_recipient] += _amount - whitelist[senderOfTx];
    }
}
