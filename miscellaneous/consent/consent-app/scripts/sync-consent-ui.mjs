import { mkdir, readdir, rm, cp, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const appRoot = path.resolve(__dirname, "..");
const distDir = path.join(appRoot, "dist");
const consentUiDir = path.resolve(appRoot, "../resources/consent-ui");

async function pathExists(targetPath) {
  try {
    await stat(targetPath);
    return true;
  } catch {
    return false;
  }
}

async function clearDirectory(directoryPath) {
  await mkdir(directoryPath, { recursive: true });
  const entries = await readdir(directoryPath);
  await Promise.all(
    entries.map((entry) => rm(path.join(directoryPath, entry), { recursive: true, force: true }))
  );
}

async function copyDirectoryContents(sourceDir, destinationDir) {
  const entries = await readdir(sourceDir);
  await Promise.all(
    entries.map((entry) =>
      cp(path.join(sourceDir, entry), path.join(destinationDir, entry), {
        recursive: true,
        force: true,
      })
    )
  );
}

async function main() {
  if (!(await pathExists(distDir))) {
    throw new Error(`Build output directory not found: ${distDir}`);
  }

  await clearDirectory(consentUiDir);
  await copyDirectoryContents(distDir, consentUiDir);

  console.log(`Synced ${distDir} -> ${consentUiDir}`);
}

main().catch((error) => {
  console.error("Failed to sync consent UI assets.", error);
  process.exit(1);
});
