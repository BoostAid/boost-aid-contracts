import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PostFactoryModule = buildModule("PostFactoryModule", (m) => {
  const postFactory = m.contract("PostFactory");

  return { post: postFactory };
});

export default PostFactoryModule;
