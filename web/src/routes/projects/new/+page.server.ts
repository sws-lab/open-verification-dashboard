import { newProjectSchema } from '$lib/schemas/newProject';
import { fail, message, superValidate } from 'sveltekit-superforms';
import { zod4 } from 'sveltekit-superforms/adapters';
import type { PageServerLoad } from '../$types';
import { db } from '$lib/server/db';
import { projects } from '$lib/server/db/schema';
import sanitize from 'sanitize-filename';
import fs from 'fs';
import type { ArchiveManager } from '$lib/server/archivesManager/archivesManager';
import { zipManager } from '$lib/server/archivesManager/zipManager';
import { tarManager } from '$lib/server/archivesManager/tarManager';
import postgres from 'postgres';

export const load: PageServerLoad = async () => {
	return {
		form: await superValidate(zod4(newProjectSchema))
	};
};

interface FormData {
	data: {
		name: string;
		description?: string | undefined;
	};
}

async function checkUnzipedSize<T extends FormData>(
	sources: File,
	manager: ArchiveManager,
	form: T
) {
	let unzippedSize = 0;
	try {
		unzippedSize = await manager.getUnzippedSize(sources);
	} catch (error) {
		console.error('Error reading file:', error);
		return fail(400, { form, error: 'Invalid project file format.' });
	}

	if (unzippedSize === 0) {
		return fail(400, { form, error: 'Project file is empty.' });
	}

	if (unzippedSize > 1024 * 1024 * 1024) {
		return fail(400, { form, error: 'Unzipped project size exceeds 1GB limit.' });
	} else {
		console.log('Uploading project...');
		console.log(`Project name: ${form.data.name}`);
		console.log(`Project description: ${form.data.description}`);
		console.log(`Project file size: ${sources.size} bytes`);
		console.log(`Unzipped project size: ${unzippedSize} bytes`);
	}
}

export const actions = {
	default: async ({ request }) => {
		const form = await superValidate(request, zod4(newProjectSchema), {
			strict: true
		});
		if (!form.valid) {
			return fail(400, { form });
		}

		const data = form.data;
		const sources = data.sources;
		if (!(sources instanceof File)) {
			return fail(400, { form, error: 'Sources must be a file.' });
		}

		const sanitized = sanitize(sources.name);
		if (sanitized !== sources.name) {
			return fail(400, { form, error: 'Invalid characters in project name.' });
		}

		// 1Gb limit for project size
		if (sources.size > 1024 * 1024 * 1024) {
			return fail(400, { form, error: 'Project size exceeds 1GB limit.' });
		}

		let manager: ArchiveManager;
		if (sources.type === 'application/zip') {
			manager = zipManager;
		} else if (sources.type === 'application/x-tar' || sources.type === 'application/gzip') {
			manager = tarManager;
		} else {
			return fail(400, { form, error: 'Unsupported project file format.' });
		}

		checkUnzipedSize(sources, manager, form);

		let errorMessage = null;
		let id = null;
		try {
			await db.transaction(async (tx) => {
				const result = await tx
					.insert(projects)
					.values({
						name: data.name,
						description: data.description
					})
					.returning();
				id = result[0].id;
				const destination = `projects/${result[0].id}/${result[0].revision}`;
				if (!fs.existsSync(destination)) {
					fs.mkdirSync(destination, { recursive: true });
				}
				await manager.extractFile(sources, destination);
				console.log(`Project files extracted to: ${destination}`);
			});
		} catch (error) {
			if (error instanceof postgres.PostgresError && error.code === '23505') {
				console.error('Project creation failed: Duplicate project name');
				errorMessage = 'Project with this name already exists.';
			} else {
				console.error('Error creating project:', error);
				errorMessage = 'Failed to create project.';
			}

			return fail(500, { form, error: errorMessage });
		}
		console.log('Project created successfully with ID:', id);
		return message(form, {
			text: 'Project created successfully!',
			id
		});
	}
};
