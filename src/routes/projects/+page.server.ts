import type { PageServerLoad } from "./$types";
import { db } from "$lib/server/db";

export const load: PageServerLoad = async () => {
	try {
		const projects = await db.query.projects.findMany()
		return { errored: false, message: '', projects };
	} catch (error: any) {
		console.error(error);
		return { errored: true, message: error.message, projects: [] };
	}
}