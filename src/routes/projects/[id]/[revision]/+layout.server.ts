import { db } from '$lib/server/db';
import { projects } from '$lib/server/db/schema';
import { eq } from 'drizzle-orm';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from '../../$types';


export const load: PageServerLoad = async ({ params }) => {
	const { id, revision } = params;
	let project;
	try {
		project = await db.select()
			.from(projects)
			.where(eq(projects.id, id));
	} catch (err) {
		console.error('Error loading project:', err);
		error(500, { message: 'Internal server error' });
	}
	if (project.length === 0) {
		error(404, { message: 'Project not found' });
	}

	const projectData = project[0];
	return {
		project: projectData,
		revision: revision,
	}
}