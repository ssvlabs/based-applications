import { Wallet, ethers } from "ethers";

const wallet = Wallet.createRandom();
const address = wallet.address;

const message = "Hello, Ethereum!";
const messageHash = ethers.hashMessage(message); // personal_sign style
const signature = await wallet.signMessage(message);

// ABI-encode the triple (address, bytes32, bytes)
const abiEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
  ["address", "bytes32", "bytes"],
  [address, messageHash, signature]
);

console.log("✅ Generated test input:");
console.log("Signer Address     :", address);
console.log("Message            :", message);
console.log("Message Hash       :", messageHash);
console.log("Signature          :", signature);
console.log("ABI Encoded Payload:", abiEncoded);