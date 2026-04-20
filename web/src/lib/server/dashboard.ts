import { env } from '$env/dynamic/private';
import type { DashboardOutput } from '$lib/conflicts/conflict';
import { spawn } from 'node:child_process';
import os from 'node:os';
import fs from 'node:fs';

interface ProofObligation {
	id: number;
	projectId: number;
	projectRevision: number;
	proofObligation: unknown;
}

type returnType =
	| {
			success: true;
			data: DashboardOutput;
	  }
	| {
			success: false;
			error: string;
	  };

export async function compareProofObligations(
	proofObligation1: ProofObligation,
	proofObligation2: ProofObligation
): Promise<returnType> {
	const workingDir = `./projects/${proofObligation1.projectId}/${proofObligation1.projectRevision}`;
	const uuid = crypto.randomUUID();

	console.log(
		`Starting dashboard process for project ${proofObligation1.projectId} revision ${proofObligation1.projectRevision} with UUID ${uuid}`
	);
	const dashboard = spawn(
		env.DASHBOARD_APP_PATH,
		[
			'stdin',
			'stdin',
			'--project',
			'.',
			'--output',
			`../../${uuid}.json`,
			'--exclude-not-found',
			'true'
		],
		{
			cwd: workingDir,
			shell: false,
			stdio: ['pipe', 'pipe', 'pipe']
		}
	);

	dashboard.stdout.on('data', (data) => {
		console.log(`Dashboard stdout: ${data}`);
	});
	dashboard.stderr.on('data', (data) => {
		console.error(`Dashboard stderr: ${data}`);
	});

	const programPromise = new Promise<{ success: boolean; error?: string }>((resolve, _) => {
		dashboard.on('error', (err) => {
			console.error('Error starting dashboard process:', err);
			resolve({ success: false, error: 'Internal server error' });
		});

		dashboard.on('exit', async (code) => {
			if (code === 1) {
				console.error(`Dashboard process exited with code ${code}`);
				resolve({ success: false, error: 'Dashboard process failed' });
				return;
			}
			console.log('Dashboard process completed');
			resolve({ success: true });
		});
	});

	dashboard.stdin.write(JSON.stringify(proofObligation1.proofObligation) + os.EOL);
	dashboard.stdin.write(JSON.stringify(proofObligation2.proofObligation) + os.EOL);
	dashboard.stdin.end();

	const result = await programPromise;
	if (!result.success) {
		return {
			success: false,
			error: result.error || 'Unknown error occurred'
		};
	}
	return {
		success: true,
		data: JSON.parse(fs.readFileSync(`./projects/${uuid}.json`, 'utf-8')) as DashboardOutput
	};
}
