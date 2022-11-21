//SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error InvalidAmount();
error Unsuccessful();
error PaymentFailed();
error NotAdmin();

contract Escrow{

    address owner;
    address immutable ETH = 0x0000000000000000000000000000000000000000;

/*
=====================================================================================================
============================================ MODIFIER ===============================================
=====================================================================================================
*/
    modifier ifAdmin() {
        if (msg.sender != owner) revert NotAdmin();
        _;
    }

/*
=====================================================================================================
==================================== MAPPINGS AND STORAGE ===========================================
=====================================================================================================
*/
    mapping(address => mapping(uint256 => bytes32)) public txs;
    mapping(bytes32 => bool) received;
    mapping(address => bool) merchants;
    
    address[] public merchantId;
    uint256 txId;

/*
=====================================================================================================
============================================= EVENTS ================================================
=====================================================================================================
*/
    event EscrowSupplied(address token, bytes32 txs, uint256 amount);
    event FundsReceived(bytes32 txs, uint256 amount, address merchant);
    event FundsWithdrawn(bytes32 txs, uint256 amount, address buyer);
    event NewMerchantAdded(address[] _merchants);
    event MerchantsRemoved(address[] _merchantId);

/*
=====================================================================================================
========================================= CONSTRUCTOR ===============================================
=====================================================================================================
*/
    constructor(){
        owner = msg.sender;
    }

/*
=====================================================================================================
=========================================== FUNCTIONS ===============================================
=====================================================================================================
*/

    ///@notice Allows the deposit of funds
    ///@dev Function receives tx details and encodes parameters in bytes32
    ///@param  _token - The token address supplied
    ///@param _txDetails - The text-transaction details in bytes32
    ///@param _amount - The amount supplied
    function Supply(address _token, bytes32 _txDetails, uint _amount) external {
        if(_amount == 0) revert InvalidAmount();

        if(_token == ETH){
            (bool success, ) = payable(address(this)).call{
            value: _amount,
            gas: 20000
            }("");
            require(success);

            //encodes parameters in bytes32
            txs[msg.sender][txId] = keccak256(abi.encode(_txDetails, ETH, _amount));
            txId++;
        } else {
            bool sent = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
            if(!sent) revert Unsuccessful();
            
            //encodes parameters in bytes32
            txs[msg.sender][txId] = keccak256(abi.encode(_txDetails, _token, _amount));
            txId++;
        }

        emit EscrowSupplied(_token, txs[msg.sender][txId], _amount);
    }

    ///@notice Allows the withdrawal of funds to merchants
    ///@dev Function receives tx details and compares values
    ///@param  _token - The token address supplied
    ///@param _txDetails - The text-transaction details in bytes32(most important for withdrawal)
    ///@param _amount - The amount supplied
    ///@param _txId - transaction index
    ///@param _buyer - the buyer
    function receiveFunds(bytes32 _txDetails, address _token, uint256 _amount, uint256 _txId, address _buyer) external {
        require(merchants[msg.sender] == true, "NOT_MERCHANT");
        require(!received[txs[_buyer][_txId]], "ALREADY_WITHDRAWN");

        bytes32 _tx = txs[_buyer][_txId];
        bytes memory txDetails = bytes.concat(_tx);
        (bytes32 data, address txToken, uint256 amount) = abi.decode(txDetails, (bytes32, address, uint256));
        require(data == _txDetails);
        require(txToken == _token);
        require(amount == _amount);

        if(txToken == ETH){
            (bool success, ) = payable(msg.sender).call{
                value: amount,
                gas: 20000
            }("");
            require(success);
        } else {
            bool sent = IERC20(txToken).transferFrom(address(this), msg.sender, amount);
            if(!sent) revert PaymentFailed();
        }

        received[_tx] = true;
        emit FundsReceived(_tx, _amount, msg.sender);
    }

    ///@notice Allows the withdrawal of funds back to owner
    ///@param _txId - transaction index
    function withdrawFunds(uint256 _txId) external {
        require(!received[txs[msg.sender][_txId]], "ALREADY_WITHDRAWN");

        bytes32 _tx = txs[msg.sender][_txId];
        bytes memory txDetails = bytes.concat(_tx);
        (, address sentToken, uint256 amount) = abi.decode(txDetails, (bytes32, address, uint256));
         
        if(sentToken == ETH){
            (bool success, ) = payable(msg.sender).call{
                value: amount,
                gas: 20000
            }("");
            require(success);
        } else {
            bool sent = IERC20(sentToken).transferFrom(address(this), msg.sender, amount);
            if(!sent) revert PaymentFailed();
        }
        
        received[_tx] = true;
        emit FundsWithdrawn(_tx, amount, msg.sender);
    }

/*
=====================================================================================================
============================================= SETTERS ===============================================
=====================================================================================================    
*/
    ///@dev Only admin can add merchants
    ///@param _merchants An array of new merchant's addresses to be added 
    function addMerchant(address[] calldata _merchants) ifAdmin external {
        for(uint256 i=0; i < _merchants.length;){
            require(_merchants[i] != address(0), "INVALID");
            if(merchants[_merchants[i]] != true){
                merchants[_merchants[i]] = true;
                merchantId.push(_merchants[i]);
            }
        unchecked{
            i++; 
            }
        }
        emit NewMerchantAdded(_merchants);
    } 

    ///@dev Only admin can remove merchants
    ///@param _merchantId An array of merchant's addresses to be removed
    function removeMerchant(address[] calldata _merchantId) ifAdmin external {
        for(uint256 i=0; i < _merchantId.length;){
            if(merchants[_merchantId[i]] == true){
                merchants[_merchantId[i]] = false;
                merchantId.pop();
            }
        unchecked{
            i++;
            }
        }
        emit MerchantsRemoved(_merchantId);
    }

    ///@dev Ethers receive function
    receive() external payable{}
}