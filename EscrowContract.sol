// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
contract Escrow {
    address public recipientA;
    address public recipientB;
    address public tokenA;
    address public tokenB;
    uint public amountA; 
    uint public amountB;
    enum Status { 
       created,
       depositPending,
       claimPending,
       compeleted,
       cancelled
    }
    Status public status;

    constructor(
        address _recipientA,
        address _recipientB,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB        
    )validTokens(_tokenA,_tokenB) {
        recipientA = _recipientA;
        recipientB = _recipientB;
        tokenA = _tokenA;
        tokenB = _tokenB;
        amountA = _amountA;
        amountB = _amountB;
        status = Status.created;
    }

    modifier validRecipients { 
        require(recipientA == msg.sender || recipientB == msg.sender, "Escrow Instances Not Found For this Address");
        _;
    }
    modifier validTokens (address _tokenA, address _tokenB){
        require(_tokenA!=tokenB,"Tokens Must Not Be Same");
        require(_tokenA!=address(0) && _tokenB!=address(0),"Invalid Token Address");
        _;
    }

    function deposit() validRecipients external {
        ERC20 token = (recipientA == msg.sender) ? ERC20(tokenA) : ERC20(tokenB);
        uint amount = (recipientA == msg.sender) ? amountA : amountB;
        require(token.allowance(msg.sender, address(this)) >= amount, "Please Approve Tokens To The Contract");
        token.transferFrom(msg.sender, address(this), amount); 
        if (ERC20(tokenA).balanceOf(address(this)) >= amountA && ERC20(tokenB).balanceOf(address(this)) >= amountB) {
            status = Status.claimPending;
        } else { 
            status = Status.depositPending;
        }
    }

    function gasLessDeposit(    // Function will revert if token doesnot supports permit
        address _token,
        address _sender,
        uint _amount,   
        uint _deadLine,
        uint8 _v,bytes32 _r,bytes32 _s
    ) validRecipients external{
        require(_token==tokenA || _token==tokenB);
        require(_sender == recipientA || _sender == recipientB);
        ERC20Permit(_token).permit(
           _sender,address(this),_amount,_deadLine,_v,_r,_s);
        ERC20(_token).transferFrom(_sender,address(this),_amount);
         if (ERC20(tokenA).balanceOf(address(this)) >= amountA && ERC20(tokenB).balanceOf(address(this)) >= amountB) {
            status = Status.claimPending;
        } else { 
            status = Status.depositPending;
        }
    }
     
    function claim() external validRecipients {
        require(ERC20(tokenA).balanceOf(address(this)) >= amountA);
        require(ERC20(tokenB).balanceOf(address(this)) >= amountB);
        require(status == Status.claimPending, "Deposit not Completed");
        ERC20(tokenA).transfer(recipientB, amountA - (amountA * 10 / 10000));
        ERC20(tokenB).transfer(recipientA, amountB - (amountB * 10 / 10000));
        status = Status.compeleted;
    }

    function cancel() external validRecipients {
        require(status == Status.depositPending, "Deposits Already Made, Unable To Cancel");
        ERC20 token = (recipientA == msg.sender) ? ERC20(tokenA) : ERC20(tokenB);
        uint amount = (recipientA == msg.sender) ? amountA : amountB;
        token.transfer(msg.sender, amount);
    }
}
