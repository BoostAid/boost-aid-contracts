# boost-aid-contracts

Here we host the smart contracts for the boost aid project.

Smart Contracts are located inside the contracts folder.

## Project Setup

1. Make sure you are using node lts, recommend to use nvm so that you can easilly switch node versions see more here: https://github.com/nvm-sh/nvm
2. Run npm install in root directory to install all dependencies.

## Compile Contracts

To compile contracts run `npx hardhat compile`.

## Running Tests

To test the contracts run `npx hardhat test`.

## Deploying

To deploy the contracts run the command `npx hardhat ignition deploy ignition/modules/PostFactory.ts --network [arbitrumSepolia] --deployment-id [postFactoryTestDeployment]`. The value beside `--network` is the name of the network, can be found by using `npx hardhat verify --list-networks`. The value beside `--deployment-id` is the name of the deployment, will be added to ignition/deployments, used to verify the contact after deploying it.

## Verifying

To verify a contract run the command `npx hardhat verify --network [network] [deployment address]`. Replace the `[network]` with the value from `npx hardhat verify --list-networks` you wish to use. Replace `[deployment address]` with the address that the previous command gave out.
