import checkApiSchema from "$lib/schemas/apiJsonCheck";
import { json, type RequestHandler } from "@sveltejs/kit";
import * as checks from "$lib/schemas/proofObligationsComparison";
import { db } from "$lib/server/db";
import { conflict, proofObligation } from "$lib/server/db/schema";
import { and, eq, or } from "drizzle-orm";
import { spawn } from "child_process";
import fs from "fs";
import os from "os";
import { env } from "$env/dynamic/private";
import { Readable } from "stream";

export const POST: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}

	try {
		const comparison = await db.select({ id: conflict.id })
			.from(conflict)
			.where(
				and(
					eq(conflict.proofObligationId1, result.data.proofObligationId1),
					eq(conflict.proofObligationId2, result.data.proofObligationId2),
				)
			).limit(1);
		if (comparison.length > 0) {
			return json({ id: comparison[0].id });
		}
	} catch (err) {
		console.error("Error fetching comparison:", err);
		return json({ success: false, error: "Internal server error" }, { status: 500 });
	}

	const proofObligations = await db.select({
		id: proofObligation.id,
		projectId: proofObligation.projectId,
		projectRevision: proofObligation.projectRevision,
		proofObligation: proofObligation.proofObligation,
	}).from(proofObligation)
		.where(
			or(
				eq(proofObligation.id, result.data.proofObligationId1),
				eq(proofObligation.id, result.data.proofObligationId2)
			)
		).limit(2);

	if (proofObligations.length !== 2) {
		return json({ success: false, error: "Proof obligations not found" }, { status: 404 });
	}

	const [proofObligation1, proofObligation2] = proofObligations;

	const workingDir = `./projects/${proofObligation1.projectId}/${proofObligation1.projectRevision}`;
	const uuid = crypto.randomUUID();

	console.log(`Starting dashboard process for project ${proofObligation1.projectId} revision ${proofObligation1.projectRevision} with UUID ${uuid}`);
	const dashboard = spawn(env.DASHBOARD_APP_PATH, [
		"stdin", "stdin", "--project", ".", "--output", `../../${uuid}.json`
	], {
		cwd: workingDir,
		shell: false,
		stdio: ["pipe", "pipe", "pipe"]
	});

	dashboard.stdout.on("data", (data) => {
		console.log(`Dashboard stdout: ${data}`);
	});
	dashboard.stderr.on("data", (data) => {
		console.error(`Dashboard stderr: ${data}`);
	});

	const programPromise = new Promise<{ success: boolean; error?: string }>((resolve, reject) => {
		dashboard.on("error", (err) => {
			console.error("Error starting dashboard process:", err);
			resolve({ success: false, error: "Internal server error" });
		});

		dashboard.on("exit", async (code) => {
			if (code !== 0) {
				console.error(`Dashboard process exited with code ${code}`);
				resolve({ success: false, error: "Dashboard process failed" });
				return;
			}
			console.log("Dashboard process completed");
			resolve({ success: true });
		})
	});

	dashboard.stdin.write(JSON.stringify(proofObligation1.proofObligation) + os.EOL);
	dashboard.stdin.write(JSON.stringify(proofObligation2.proofObligation) + os.EOL);
	dashboard.stdin.end();

	let dashboard_result;
	try {
		console.log("Waiting for dashboard process to complete...");
		const program_output = await programPromise;
		if (!program_output.success) {
			return json(program_output, { status: 500 });
		}
		dashboard_result = JSON.parse(fs.readFileSync(`./projects/${uuid}.json`, 'utf-8'));
	} catch (err) {
		console.error("Error during dashboard process execution:", err);
		return json({ success: false, error: "Internal server error" }, { status: 500 });
	}

	try {
		const id = await db.insert(conflict).values({
			projectId: proofObligation1.projectId,
			projectRevision: proofObligation1.projectRevision,
			proofObligationId1: proofObligation1.id,
			proofObligationId2: proofObligation2.id,
			conflicts: dashboard_result,
		}).returning({ id: conflict.id });
		if (id.length > 0) {
			return json({ id: id[0].id });
		}
	} catch (err) {
		console.error("Error inserting conflict into database:", err);
		return json({ success: false, error: "Internal server error" }, { status: 500 });
	}

	return json({ success: false, error: "Should never be reached" }, { status: 418 });
}