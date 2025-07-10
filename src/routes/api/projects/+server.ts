import type { RequestHandler } from "./$types";
import { db } from "$lib/server/db";
import { json } from "@sveltejs/kit";
import { ilike } from "drizzle-orm";
import { projects } from "$lib/server/db/schema";

export const GET: RequestHandler = async ({ url }) => {
	try {
		const filter = url.searchParams.get("filter") || "";
		let whereClause = {};
		if (filter) {
			whereClause = {
				where: ilike(projects.name, filter)
			}
		}
		return json({
			projects: await db.query.projects.findMany(whereClause)
		});
	} catch (error: any) {
		console.error(error);
		return error(500, { message: error.message });
	}
}