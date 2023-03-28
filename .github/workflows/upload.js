const fs = require("fs").promises;
const crypto = require("crypto");
const zlib = require("zlib");
const tar = require("tar-fs");
const { basename } = require("path");

const PROJECT = "sqlite-lines";
const extension = {
  name: "lines0",
  description: "",
  platforms: [
    {
      path: "sqlite-lines-linux_x86/lines0.so",
      os: "linux",
      cpu: "x86_64",
    },
    {
      path: "sqlite-lines-macos/lines0.dylib",
      os: "darwin",
      cpu: "x86_64",
    },
  ],
};

function targz(files) {
  return new Promise((resolve, reject) => {
    console.log("targz files: ", files[0].name, files[0]);

    const tarStream = tar.pack();

    for (const file of files) {
      tarStream.entry({ name: file.name }, file.data);
    }

    tarStream.finalize();

    const gzip = zlib.createGzip();

    const chunks = [];
    tarStream
      .pipe(gzip)
      .on("data", (chunk) => {
        chunks.push(chunk);
      })
      .on("end", () => {
        const buffer = Buffer.concat(chunks);
        resolve(buffer);
      })
      .on("error", reject);
  });
}

module.exports = async ({ github, context }) => {
  const {
    repo: { owner, repo },
    sha,
  } = context;
  const VERSION = process.env.GITHUB_REF_NAME;

  const release = await github.rest.repos.getReleaseByTag({
    owner,
    repo,
    tag: process.env.GITHUB_REF.replace("refs/tags/", ""),
  });
  const release_id = release.data.id;

  async function uploadPlatform(platform) {
    const { path, os, cpu } = platform;

    const artifact = basename(path);
    const contents = await fs.readFile(path);
    const tar = await targz([{ name: artifact, data: contents }]);

    const asset_name = `${PROJECT}-${VERSION}-${os}-${cpu}.tar.gz`;
    const asset_md5 = crypto.createHash("md5").update(tar).digest("base64");
    const asset_sha256 = crypto.createHash("sha256").update(tar).digest("hex");

    await github.rest.repos.uploadReleaseAsset({
      owner,
      repo,
      release_id,
      name: asset_name,
      data: tar,
    });

    return {
      os,
      cpu,
      asset_name,
      asset_sha256,
      asset_md5,
    };
  }

  const spm_json = {
    version: 0,
    extensions: {
      [extension.name]: {
        description: extension.description,
        platforms: await Promise.all(
          extension.platforms.map((platform) => uploadPlatform(platform))
        ),
      },
    },
  };

  await github.rest.repos.uploadReleaseAsset({
    owner,
    repo,
    release_id,
    name: "spm.json",
    data: JSON.stringify(spm_json),
  });
};
