const fs = require("fs").promises;

module.exports = async ({ github, context }) => {
  const {
    repo: { owner, repo },
    sha,
  } = context;
  console.log(process.env.GITHUB_REF);
  const release = await github.rest.repos.getReleaseByTag({
    owner,
    repo,
    tag: process.env.GITHUB_REF.replace("refs/tags/", ""),
  });

  const release_id = release.data.id;
  async function uploadReleaseAsset(name, path) {
    console.log("Uploading", name, "at", path);

    return github.rest.repos.uploadReleaseAsset({
      owner,
      repo,
      release_id,
      name,
      data: await fs.readFile(path),
    });
  }
  await Promise.all([
    uploadReleaseAsset("lines0.so", "lines0-linux-amd64/lines0.so"),
    uploadReleaseAsset(
      "lines0-linux-amd64-sqlite-lines",
      "lines0-linux-amd64/sqlite-lines"
    ),
    uploadReleaseAsset(
      "lines0-linux-amd64-sqlite3",
      "lines0-linux-amd64/sqlite3"
    ),
    uploadReleaseAsset(
      "lines0-linux-amd64.zip",
      "lines0-linux-amd64/package.zip"
    ),
    uploadReleaseAsset("lines0.dylib", "lines0-darwin-amd64/lines0.dylib"),
    uploadReleaseAsset(
      "lines0-darwin-amd64-sqlite-lines",
      "lines0-darwin-amd64/sqlite-lines"
    ),
    uploadReleaseAsset(
      "lines0-darwin-amd64-sqlite3",
      "lines0-darwin-amd64/sqlite3"
    ),
    uploadReleaseAsset(
      "lines0-darwin-amd64.zip",
      "lines0-darwin-amd64/package.zip"
    ),
    uploadReleaseAsset("lines0-sqljs.wasm", "lines0-sqljs/sqljs.wasm"),
    uploadReleaseAsset("lines0-sqljs.js", "lines0-sqljs/sqljs.js"),
  ]);

  return;
};
