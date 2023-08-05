const fs = require("fs").promises;

const compiled_extensions = [
  {
    path: "sqlite-lines-macos/lines0.dylib",
    name: "deno-darwin-x86_64.lines0.dylib",
  },
  {
    path: "sqlite-lines-macos-aarch64/lines0.dylib",
    name: "deno-darwin-aarch64.lines0.dylib",
  },
  {
    path: "sqlite-lines-linux_x86/lines0.so",
    name: "deno-linux-x86_64.lines0.so",
  },
];

module.exports = async ({ github, context }) => {
  const { owner, repo } = context.repo;
  const release = await github.rest.repos.getReleaseByTag({
    owner,
    repo,
    tag: process.env.GITHUB_REF.replace("refs/tags/", ""),
  });
  const release_id = release.data.id;

  await Promise.all(
    compiled_extensions.map(async ({ name, path }) => {
      return github.rest.repos.uploadReleaseAsset({
        owner,
        repo,
        release_id,
        name,
        data: await fs.readFile(path),
      });
    })
  );
};
