import { access, readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const requestedProjects = process.argv.slice(2);
let projectNames = requestedProjects;
if (!projectNames.length) {
  const directories = (await readdir('.', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);
  const candidates = await Promise.all(directories.map(async (name) => {
    try {
      await access(path.join(name, 'project.json'));
      return name;
    } catch {
      return null;
    }
  }));
  projectNames = candidates.filter(Boolean).sort();
}

if (!projectNames.length) throw new Error('No projects with project.json found');

for (const projectName of projectNames) {
  if (!/^[A-Za-z0-9_]+$/.test(projectName)) throw new Error(`Invalid project name: ${projectName}`);
  const projectDir = path.resolve(projectName);
  const config = JSON.parse(await readFile(path.join(projectDir, 'project.json'), 'utf8'));
  for (const field of ['name', 'tempoBpm', 'renderDurationSeconds', 'smokeDurationSeconds']) {
    if (!(field in config)) throw new Error(`${projectName}/project.json is missing ${field}`);
  }
  for (const field of ['tempoBpm', 'renderDurationSeconds', 'smokeDurationSeconds']) {
    if (!Number.isFinite(config[field]) || config[field] <= 0) {
      throw new Error(`${projectName}/project.json ${field} must be a positive number`);
    }
  }
  if (config.smokeDurationSeconds > config.renderDurationSeconds) {
    throw new Error(`${projectName}: smoke duration exceeds render duration`);
  }
  await Promise.all(['strudel.html', 'main.scd', 'export_wav.scd', 'main.csd'].map((file) => access(path.join(projectDir, file))));
  console.log(`Validated ${projectName} (${config.renderDurationSeconds}s)`);
}
