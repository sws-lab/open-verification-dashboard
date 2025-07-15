import type { PageServerLoad } from "./$types";
import { getProjects } from "$lib/server/db/projectPages";

export const load: PageServerLoad = async ({ url }) => {
	try {
		let page = parseInt(url.searchParams.get("page") || "1", 10);
		if (isNaN(page) || page < 1) {
			page = 1;
		}
		let filter = url.searchParams.get("filter") || "";
		if (filter.length > 100) {
			filter = "";
		}

		let {pages, projects} = await getProjects(page, filter);
		return {
			errored: false,
			message: '', 
			projects,
			page,
			totalPages: pages,
			filter
		};
	} catch (error: any) {
		console.error(error);
		return { errored: true, message: error.message, projects: [], page: 1, totalPages: 0, filter: "" };
	}
}