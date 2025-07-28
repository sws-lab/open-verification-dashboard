import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { getProjects } from '$lib/server/db/projectPages';
import { db } from '$lib/server/db';
import { projects } from '$lib/server/db/schema';
import fs from 'fs';
import { eq, sql } from 'drizzle-orm';
import * as checks from '$lib/schemas/projects';
import checkApiSchema from '$lib/schemas/apiJsonCheck';

export const GET: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.GET);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { filter, page } = result.data;
	try {
		return json(await getProjects(page, filter));
	} catch (err) {
		console.error(err);
		return json(
			{
				error: 'An error occurred while fetching projects'
			},
			{ status: 500 }
		);
	}
};

export const POST: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.POST);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { name, description, projectId } = result.data;
	try {
		const updated: { count: number }[] = await db
			.update(projects)
			.set({ name, description })
			.where(eq(projects.id, projectId))
			.returning({ count: sql<number>`count(*)` });

		if (updated[0].count === 0) {
			return json({ error: 'Project not found' }, { status: 404 });
		}
	} catch (err) {
		console.error(err);
		return json(
			{
				error: 'An error occurred while updating the project'
			},
			{ status: 500 }
		);
	}
	return new Response(null, { status: 204 });
};

export const DELETE: RequestHandler = async ({ request }) => {
	const result = await checkApiSchema(request, checks.DELETE);
	if (!result.success) {
		return json(result, { status: 400 });
	}
	const { projectId } = result.data;
	if (typeof projectId !== 'number') {
		return json({ error: 'Invalid project ID' }, { status: 400 });
	}
	try {
		await db.transaction(async (tx) => {
			const path = `./projects/${projectId}`;
			if (fs.existsSync(path)) {
				fs.rmSync(path, { recursive: true, force: true });
			}
			await tx.delete(projects).where(eq(projects.id, projectId));
		});
	} catch (err) {
		console.error(err);
		return json(
			{
				error: 'An error occurred while deleting the project'
			},
			{ status: 500 }
		);
	}
	return new Response(null, { status: 204 });
};
