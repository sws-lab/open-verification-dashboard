import type { RequestHandler } from "./$types";
import { json } from "@sveltejs/kit";
import { getProjects } from "$lib/server/db/projectPages";

export const GET: RequestHandler = async ({ url }) => {
	try {
		const filter = url.searchParams.get("filter") || "";
		const page = parseInt(url.searchParams.get("page") || "1", 10);
		if (isNaN(page) || page < 1) {
			return json({ error: "Invalid page number" }, { status: 400 });
		}
		return json(await getProjects(page, filter));
	} catch (err: any) {
		console.error(err);
		return json({
			error: err.message || "An error occurred while fetching projects"
		}, { status: 500 });
	}
}