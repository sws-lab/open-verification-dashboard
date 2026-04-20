import { fail, superValidate } from 'sveltekit-superforms';
import type { PageServerLoad } from '../../../$types';
import { zod4 } from 'sveltekit-superforms/adapters';
import { newProofObligationSchema } from '$lib/schemas/newProofObligation';
import { projects } from '$lib/server/db/schema';
import { getProofObligation } from '$lib/server/db/proofObligationPages';
import { error } from '@sveltejs/kit';
import { newProofObligation } from '$lib/server/proofObligations';

export const load: PageServerLoad = async ({ url, parent, depends }) => {
	depends('app:proofObligations');

	const data = await parent();
	const { project } = data as {
		project: typeof projects.$inferSelect;
	};

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
			return fail(400, { form, message: 'Please upload a valid file.' });
		}
		if (sources.size > 500 * 1024 * 1024) {
			// 500 MB max file size
			return fail(400, { form, message: 'File size exceeds the maximum limit of 500 MB.' });
		}

		const id = parseInt(params.id);
		const revision = parseInt(params.revision);

		console.log('Creating proof obligation for project:', id, 'revision:', revision);
		const proofObligationJSON = JSON.parse(await sources.text()); // this has a limit of ~500 MB

		const result = await newProofObligation(id, revision, data.name, proofObligationJSON);
		if (result.code !== 200) {
			return fail(result.code, { form, error: result.error, issues: result.issues });
		}
	}
};
