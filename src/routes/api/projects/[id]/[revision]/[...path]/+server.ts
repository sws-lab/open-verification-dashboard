import { db } from "$lib/server/db";
import { projects } from "$lib/server/db/schema";
import { json, type RequestHandler } from "@sveltejs/kit";
import { eq, gte, and } from "drizzle-orm";
import fs from "fs";

export const GET: RequestHandler = async ({ params }) => {
	const { id, revision, path } = params;

	try {
		const project = await db.select()
			.from(projects)
			.where(and(
				eq(projects.id, Number(id)),
				gte(projects.revision, Number(revision))
			))
			.limit(1)
		if (project.length === 0) {
			return json({ error: "Project not found" }, { status: 404 });
		}
	} catch (error) {
		console.error("Error fetching project:", error);
		return json({ error: "An error occurred while fetching the project" }, { status: 500 });
	}
	
	const filePath = `./projects/${id}/${revision}/${path}`;
	if (!fs.existsSync(filePath)) {
		return json({ error: "File not found" }, { status: 404 });
	}

	if (fs.statSync(filePath).isDirectory()) {
		const files = fs.readdirSync(filePath);
		return json({ 
			type: "directory",
			path,
			files: files.map(file => ({
				name: file,
				type: fs.statSync(`${filePath}/${file}`).isDirectory() ? "directory" : "file"
			}))
		});
	} else {
		const content = fs.readFileSync(filePath, "utf-8");
		return json({ 
			type: "file",
			path,
			content 
		});
	}
}