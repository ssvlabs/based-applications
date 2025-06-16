import { Wallet, ethers } from "ethers";

const wallet = Wallet.createRandom();
const signer = wallet.address;
const signingKey = new ethers.SigningKey(wallet.privateKey);

const message = "Hello, Ethereum!";
const messageHash = ethers.hashMessage(message)

const signature = signingKey.sign(messageHash);

if(signer != ethers.recoverAddress(messageHash, signature)) {
  throw new Error("Signature verification failed");
}

console.log("✅ Generated test input:");
console.log("Signer Address   :", signer);
console.log("Message          :", message);
console.log("Message Hash     :", messageHash);
console.log("Signature        :", signature.serialized);
