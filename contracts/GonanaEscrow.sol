// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GonanaEscrow is ReentrancyGuard, Pausable, Ownable {
    
    enum Status { PENDING, SHIPPED, COMPLETED, REFUNDED, DISPUTED }
    
    struct Order {
        address buyer;
        address seller;
        uint256 amount;
        Status status;
        uint256 createdAt;
        uint256 shippedAt;
    }
    
    mapping(uint256 => Order) public orders;
    uint256 public orderCount;
    
    uint256 public platformFee = 500; // 5% (basis points)
    uint256 public constant MAX_FEE = 1000; // 10% max
    uint256 public constant DISPUTE_PERIOD = 7 days;
    uint256 public constant AUTO_COMPLETE_PERIOD = 7 days;
    
    event OrderCreated(uint256 indexed orderId, address indexed buyer, address indexed seller, uint256 amount);
    event OrderShipped(uint256 indexed orderId);
    event OrderCompleted(uint256 indexed orderId);
    event OrderRefunded(uint256 indexed orderId);
    event OrderDisputed(uint256 indexed orderId);
    event FeeUpdated(uint256 newFee);
    
    error InvalidAmount();
    error InvalidAddress();
    error Unauthorized();
    error InvalidStatus();
    error TransferFailed();
    error DisputePeriodActive();
    
    constructor() Ownable(msg.sender) {}
    
    // Create escrow order
    function createOrder(address _seller) 
        external 
        payable 
        whenNotPaused 
        nonReentrant 
        returns (uint256) 
    {
        if (msg.value == 0) revert InvalidAmount();
        if (_seller == address(0) || _seller == msg.sender) revert InvalidAddress();
        
        orderCount++;
        orders[orderCount] = Order({
            buyer: msg.sender,
            seller: _seller,
            amount: msg.value,
            status: Status.PENDING,
            createdAt: block.timestamp,
            shippedAt: 0
        });
        
        emit OrderCreated(orderCount, msg.sender, _seller, msg.value);
        return orderCount;
    }
    
    // Seller marks as shipped
    function markShipped(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if (msg.sender != order.seller) revert Unauthorized();
        if (order.status != Status.PENDING) revert InvalidStatus();
        
        order.status = Status.SHIPPED;
        order.shippedAt = block.timestamp;
        
        emit OrderShipped(_orderId);
    }
    
    // Buyer confirms delivery
    function confirmDelivery(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if (msg.sender != order.buyer) revert Unauthorized();
        if (order.status != Status.SHIPPED) revert InvalidStatus();
        
        _completeOrder(_orderId);
    }
    
    // Auto-complete after timeout (anyone can call)
    function autoComplete(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if (order.status != Status.SHIPPED) revert InvalidStatus();
        if (block.timestamp < order.shippedAt + AUTO_COMPLETE_PERIOD) {
            revert DisputePeriodActive();
        }
        
        _completeOrder(_orderId);
    }
    
    // Internal function to complete order
    function _completeOrder(uint256 _orderId) private {
        Order storage order = orders[_orderId];
        order.status = Status.COMPLETED;
        
        uint256 fee = (order.amount * platformFee) / 10000;
        uint256 sellerAmount = order.amount - fee;
        
        _safeTransfer(order.seller, sellerAmount);
        _safeTransfer(owner(), fee);
        
        emit OrderCompleted(_orderId);
    }
    
    // Seller initiates refund
    function refundBuyer(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        if (msg.sender != order.seller) revert Unauthorized();
        if (order.status != Status.PENDING && order.status != Status.SHIPPED) {
            revert InvalidStatus();
        }
        
        order.status = Status.REFUNDED;
        _safeTransfer(order.buyer, order.amount);
        
        emit OrderRefunded(_orderId);
    }
    
    // Buyer raises dispute
    function raiseDispute(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        if (msg.sender != order.buyer) revert Unauthorized();
        if (order.status != Status.SHIPPED) revert InvalidStatus();
        if (block.timestamp < order.shippedAt + DISPUTE_PERIOD) {
            revert DisputePeriodActive();
        }
        
        order.status = Status.DISPUTED;
        emit OrderDisputed(_orderId);
    }
    
    // Owner resolves dispute
    function resolveDispute(uint256 _orderId, bool _favorBuyer) 
        external 
        onlyOwner 
        nonReentrant 
    {
        Order storage order = orders[_orderId];
        if (order.status != Status.DISPUTED) revert InvalidStatus();
        
        if (_favorBuyer) {
            order.status = Status.REFUNDED;
            _safeTransfer(order.buyer, order.amount);
            emit OrderRefunded(_orderId);
        } else {
            _completeOrder(_orderId);
        }
    }
    
    // Safe transfer helper
    function _safeTransfer(address _to, uint256 _amount) private {
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) revert TransferFailed();
    }
    
    // Admin functions
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_FEE, "Fee too high");
        platformFee = _newFee;
        emit FeeUpdated(_newFee);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // View function
    function getOrder(uint256 _orderId) 
        external 
        view 
        returns (Order memory) 
    {
        return orders[_orderId];
    }
}
