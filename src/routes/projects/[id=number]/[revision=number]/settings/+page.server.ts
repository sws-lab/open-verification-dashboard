import { fail, superValidate } from 'sveltekit-superforms';
import type { PageServerLoad } from './$types';
import { zod4 } from 'sveltekit-superforms/adapters';
import { editProjectSchema } from '$lib/schemas/editProject';
import { newRevisionSchema } from '$lib/schemas/newRevision';
import { db } from '$lib/server/db';
import { projects } from '$lib/server/db/schema';
import { eq } from 'drizzle-orm';

export const load: PageServerLoad = async ({ parent }) => {
	const { project } = await parent();

	const editForm = await superValidate(
		{
			name: project.name,
			description: project.description
		},
		zod4(editProjectSchema)
	);
	const newRevisionForm = await superValidate(zod4(newRevisionSchema));

	return {
		editForm,
		newRevisionForm,
		project
	};
};

export const actions = {
	edit: async ({ request, params }) => {
		const formData = await request.formData();
		const result = await superValidate(formData, zod4(editProjectSchema));
		const { id } = params;

		if (!result.valid) {
			return fail(400, { editForm: result });
		}

		try {
			await db
				.update(projects)
				.set({
					name: result.data.name,
					description: result.data.description
				})
				.where(eq(projects.id, Number(id)));
			return { editForm: result };
		} catch (error) {
			console.error('Error updating project:', error);
			return fail(500, { editForm: result, error: 'Failed to update project.' });
		}
	},
	revision: async ({ request }) => {
		const formData = await request.formData();
		const result = await superValidate(formData, zod4(newRevisionSchema));

		if (!result.valid) {
			return fail(400, { newRevisionForm: result });
		}

		return fail(400, { newRevisionForm: result, error: 'TODO ;(' });
	}
};
