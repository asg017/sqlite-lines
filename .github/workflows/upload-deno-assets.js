const fs = require("fs").promises;
const { createHash } = require("node:crypto");

module.exports = async ({ github, context }) => {
  const VERSION = process.env.GITHUB_REF_NAME;
  const { owner, repo } = context.repo;

  const compiled_extensions = [
    {
      path: "sqlite-lines-macos/lines0.dylib",
      name: `sqlite-lines-${VERSION}-deno-darwin-x86_64.lines0.dylib`,
    },
    {
      path: "sqlite-lines-macos-aarch64/lines0.dylib",
      name: `sqlite-lines-${VERSION}-deno-darwin-aarch64.lines0.dylib`,
    },
    {
      path: "sqlite-lines-linux_x86/lines0.so",
      name: `sqlite-lines-${VERSION}-deno-linux-x86_64.lines0.so`,
    },
  ];

  const release = await github.rest.repos.getReleaseByTag({
    owner,
    repo,
    tag: process.env.GITHUB_REF.replace("refs/tags/", ""),
  });
  const release_id = release.data.id;
  const outputAssetChecksums = [];

  await Promise.all(
    compiled_extensions.map(async ({ name, path }) => {
      const data = await fs.readFile(path);
      const checksum = createHash("sha256").update(data).digest("hex");
      outputAssetChecksums.push({ name, checksum });
      return github.rest.repos.uploadReleaseAsset({
        owner,
        repo,
        release_id,
        name,
        data,
      });
    })
  );
  return outputAssetChecksums.map((d) => `${d.checksum} ${d.name}`).join("\n");
};
