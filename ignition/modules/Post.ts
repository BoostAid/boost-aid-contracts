import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PostModule = buildModule("PostModule", (m) => {
    const post = m.contract("Post");

    return { post };
});

export default PostModule;