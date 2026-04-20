import { ProofObligationSchema } from '$lib/schemas/proofObligation';
import postgres from 'postgres';
import { db } from './db';
import { proofObligation } from './db/schema';

export async function newProofObligation(
	projectId: number,
	projectRevision: number,
	name: string,
	data: object
) {
	const json = ProofObligationSchema.safeParse(data);
	if (!json.success) {
		console.log(json);
		return {
			code: 400,
			error: 'Invalid proof obligation format.',
			issues: json.error.issues
		};
	}
	let safeCount = 0;
	let warningCount = 0;
	let errorCount = 0;
	console.log('Parsed proof obligation data');
	json.data.checks.forEach((check) => {
		switch (check.kind) {
			case 'safe':
				safeCount++;
				break;
			case 'warning':
				warningCount++;
				break;
			case 'error':
				errorCount++;
				break;
		}
	});
	try {
		const [{ id }] = await db
			.insert(proofObligation)
			.values({
				projectId,
				projectRevision,
				name,
				proofObligation: json.data,
				safe: safeCount,
				warning: warningCount,
				error: errorCount
			})
			.returning({ id: proofObligation.id });

		return {
			code: 200,
			id
		};
	} catch (error) {
		if (error instanceof postgres.PostgresError && error.code == '23505') {
			return {
				code: 409,
				error: 'Proof obligation already exists.'
			};
		} else {
			console.error('Error creating proof obligation:', error);
			return { code: 500, error: 'Failed to create proof obligation.' };
		}
	}
}
