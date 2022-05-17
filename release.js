const fs = require("fs").promises;

module.exports = async ({ github, context }) => {
  const {
    repo: { owner, repo },
    sha,
  } = context;
  console.log(process.env.GITHUB_REF);
  /*const release = await github.rest.repos.getReleaseByTag({
    owner,
    repo,
    tag: process.env.GITHUB_REF.replace("refs/tags/", ""),
  });*/
  //console.log("Release:", { release });
  for (let file of await fs.readdir("lines0-linux-amd64")) {
    console.log(file);
  }
  for (let file of await fs.readdir("lines0-darwin-amd64")) {
    console.log(file);
  }
  /*console.log("Uploading", file);
    await github.rest.repos.uploadReleaseAsset({
      owner,
      repo,
      release_id: release.data.id,
      name: file,
      data: await fs.readFile(file),
    });*/
  return;
};
