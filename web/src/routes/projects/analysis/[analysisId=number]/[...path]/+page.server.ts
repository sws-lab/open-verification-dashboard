import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ parent, params, fetch }) => {
	const data = await parent();

	const { path } = params;

	const result = await fetch(
		`/api/projects/${data.analysis.projectId}/${data.analysis.revision}/${path}`
	);
	if (!result.ok) {
		error(500, `Failed to load file: ${result.statusText}`);
	}
	if (result.status === 404) {
		error(404, `File not found: ${path}`);
	}
	const fileContent = await result.json();

	return {
		...data,
		fileContent: fileContent.content,
		path
	};
};
