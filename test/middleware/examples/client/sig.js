import { Wallet, ethers } from "ethers";

const wallet = Wallet.createRandom();
const address = wallet.address;
const signingKey = new ethers.SigningKey(wallet.privateKey);

const message = "Hello, Ethereum!";
const messageHash = Buffer.from(ethers.toBeArray(ethers.hashMessage(message)))
    

// const message2 = ethers.solidityPackedKeccak256(
//         // Array of types: declares the data types in the message.
//         ['string'],
//         // Array of values: actual values of the parameters to be hashed.
//         [message]
//     );

  const signature = signingKey.sign(messageHash);
  console.log(signature.serialized)

  const expandedSignature = ethers.Signature.from(signature);
console.log(expandedSignature)

console.log(ethers.recoverAddress(messageHash, signature));


console.log("✅ Generated test input:");
console.log("Signer Address     :", address);
console.log("Message            :", message);
console.log("Message Hash       :", messageHash);
console.log("Signature          :", signature);
