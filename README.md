# Gonana Escrow Smart Contract

Secure escrow smart contract for the Gonana commodity marketplace, deployed on BNB Chain.

## Features

✅ **Secure Escrow System** - Holds funds until delivery confirmation  
✅ **Auto-Complete** - Automatic release after 7 days  
✅ **Dispute Resolution** - Built-in dispute mechanism  
✅ **Platform Fee** - 5% fee on completed orders  
✅ **Pausable** - Emergency stop functionality  
✅ **Audit-Ready** - Uses OpenZeppelin security standards  

## Installation

```bash
npm install
```

## Configuration

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Add your private key and BscScan API key to `.env`:
```
PRIVATE_KEY=your_wallet_private_key
BSCSCAN_API_KEY=your_bscscan_api_key
```

⚠️ **NEVER commit your `.env` file!**

## Get Testnet BNB

Visit: https://testnet.bnbchain.org/faucet-smart

## Compile Contract

```bash
npx hardhat compile
```

## Deploy to BNB Testnet

```bash
npx hardhat run scripts/deploy.js --network bscTestnet
```

## Verify Contract

```bash
npx hardhat verify --network bscTestnet <CONTRACT_ADDRESS>
```

## Contract Functions

### For Buyers:
- `createOrder(address seller)` - Create order and deposit funds
- `confirmDelivery(uint256 orderId)` - Confirm receipt and release payment
- `raiseDispute(uint256 orderId)` - Raise dispute after 7 days

### For Sellers:
- `markShipped(uint256 orderId)` - Mark order as shipped
- `refundBuyer(uint256 orderId)` - Initiate refund

### For Platform Owner:
- `resolveDispute(uint256 orderId, bool favorBuyer)` - Resolve disputes
- `updatePlatformFee(uint256 newFee)` - Update platform fee
- `pause()` / `unpause()` - Emergency controls

### Public:
- `autoComplete(uint256 orderId)` - Auto-complete after7 days
- `getOrder(uint256 orderId)` - View order details

## Order Flow

1. **Buyer creates order** → Funds locked in escrow
2. **Seller marks shipped** →7-day timer starts
3. **Buyer confirms delivery** → Funds released (minus 5% fee)
4. **OR auto-complete** → After 7 days, anyone can trigger release
5. **OR dispute** → Owner resolves after 7 days

## Network Details

### BNB Chain Testnet
- **RPC URL**: https://data-seed-prebsc-1-s1.binance.org:8545
- **Chain ID**: 97
- **Symbol**: tBNB
- **Explorer**: https://testnet.bscscan.com

### BNB Chain Mainnet
- **RPC URL**: https://bsc-dataseed.binance.org/
- **Chain ID**: 56
- **Symbol**: BNB
- **Explorer**: https://bscscan.com

## Security Features

- ✅ ReentrancyGuard on all state-changing functions
- ✅ Uses `.call()` for safe transfers
- ✅ Pausable for emergency stops
- ✅ Access control with OpenZeppelin
- ✅ Custom errors for gas efficiency
- ✅ Input validation on all functions

## Testing

```bash
npx hardhat test
```


## License

MIT
