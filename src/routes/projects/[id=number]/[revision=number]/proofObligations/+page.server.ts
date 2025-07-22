import { fail, message, superValidate } from 'sveltekit-superforms';
import type { PageServerLoad } from '../../../$types';
import { zod4 } from 'sveltekit-superforms/adapters';
import { newProofObligationSchema } from '$lib/schemas/newProofObligation';
import { db } from '$lib/server/db';
import { proofObligation } from '$lib/server/db/schema';
import { getProofObligation } from '$lib/server/db/proofObligationPages';
import { error } from '@sveltejs/kit';
import { ProofObligationSchema } from '$lib/schemas/proofObligation';

export const load: PageServerLoad = async ({ url, parent, depends }) => {
	depends('app:proofObligations');
	const { project } = await parent();

	let page = parseInt(url.searchParams.get('page') || '1', 10);
	if (isNaN(page) || page < 1) {
		page = 1;
	}
	let filter = url.searchParams.get('filter') || '';
	if (filter.length > 100) {
		filter = '';
	}

	try {
		const proofObligations = await getProofObligation(page, project.id, project.revision, filter);
		return {
			project,
			proofObligations: {
				...proofObligations,
				page,
				filter
			},
			form: await superValidate(zod4(newProofObligationSchema))
		};
	} catch (err) {
		console.error('Error loading proof obligations:', err);
		error(500, { message: 'Failed to load proof obligations.' });
	}
};

export const actions = {
	default: async ({ request, params }) => {
		const form = await superValidate(request, zod4(newProofObligationSchema), {
			strict: true
		});
		if (!form.valid) {
			return fail(400, { form });
		}
		const data = form.data;
		const sources = data.proofObligation;
		if (!(sources instanceof File)) {
			return fail(400, { form: message(form, 'Please upload a valid file.') });
		}
		if (sources.size > 10 * 1024 * 1024) {
			// 10 MB max file size
			return fail(400, { form: message(form, 'File size exceeds the maximum limit of 10 MB.') });
		}

		const id = parseInt(params.id);
		const revision = parseInt(params.revision);
		try {
			const proofObligationJSON = await sources.text();
			const json = ProofObligationSchema.safeParse(JSON.parse(proofObligationJSON));
			if (!json.success) {
				console.log(json);
				return fail(400, {
					form,
					error: 'Invalid proof obligation format.',
					issues: json.error.issues
				});
			}

			let safeCount = 0;
			let warningCount = 0;
			let errorCount = 0;

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

			await db.insert(proofObligation).values({
				projectId: id,
				projectRevision: revision,
				name: data.name,
				proofObligation: json.data,
				safe: safeCount,
				warning: warningCount,
				error: errorCount
			});
			return message(form, 'Proof obligation created successfully.');
		} catch (error) {
			if (error.code == '23505') {
				return fail(400, { form: form, error: 'Proof obligation already exists.' });
			} else {
				console.error('Error creating proof obligation:', error);
				return fail(500, { form: form, error: 'Failed to create proof obligation.' });
			}
		}
	}
};
