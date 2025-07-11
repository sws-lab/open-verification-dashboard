import { newProjectSchema } from "$lib/formSchema/newProject";
import { fail, message, superValidate } from "sveltekit-superforms";
import { zod4 } from "sveltekit-superforms/adapters";
import type { PageServerLoad } from "../$types";
import { db } from "$lib/server/db";
import { projects } from "$lib/server/db/schema";
import sanitize from "sanitize-filename";
import * as tar from "tar";


export const load: PageServerLoad = async () => {
	return {
		form: await superValidate(zod4(newProjectSchema))
	};
}

export const actions = {
	default: async ({request}) => {
		const form = await superValidate(request, zod4(newProjectSchema), {
			strict: true,
		});
		if (!form.valid) {
			return fail(400, { form });
		}

		let data = form.data;
		let sources = data.sources;
		if (!(sources instanceof File)) {
			return fail(400, { form, error: "Sources must be a file." });
		}

		let sanitized = sanitize(sources.name);
		if (sanitized !== sources.name) {
			return fail(400, { form, error: "Invalid characters in project name." });
		}

		// 1Gb limit for project size
		if (sources.size > 1024 * 1024 * 1024) {
			return fail(400, { form, error: "Project size exceeds 1GB limit." });
		}
		// Check that the unzipped size is less than 1Gb
		let unzippedSize = 0;
		try {
			tar.t().on('entry', (entry: File) => {
				console.log(`Entry: ${entry.name} (${entry.size} bytes)`);
				unzippedSize += entry.size;
			})
			.on('error', (err: Error) => {
				console.error("Error reading tar file:", err);
				throw new Error("Failed to read project file.");
			}).on('end', () => {
				console.log(`Total unzipped size: ${unzippedSize} bytes`);
			})
			.write(await sources.bytes())
		} catch (error) {
			console.error("Error reading tar file:", error);
			return fail(400, { form, error: "Invalid project file format." });
		}

		if (unzippedSize > 1024 * 1024 * 1024) {
			return fail(400, { form, error: "Unzipped project size exceeds 1GB limit." });
		} else {
			console.log("Uploading project...");
			console.log(`Project name: ${data.name}`);
			console.log(`Project description: ${data.description}`);
			console.log(`Project file size: ${sources.size} bytes`);
			console.log(`Unzipped project size: ${unzippedSize} bytes`);
		}
		
		try {
			await db.transaction(async (tx) => {
				const result = await db.insert(projects).values({
					name: data.name,
					description: data.description,
				}).returning();
				let path = `projects/${result[0].id}/${result[0].revision}`;
				tar.x({ C: path }).on('finish', () => {
					console.log(`Project ${result[0].name} created successfully.`);
				}).on('error', (err) => {
					console.error("Error extracting project files:", err);
					throw new Error("Failed to extract project files.");
				}).write(await sources.bytes());
			})
		} catch (error) {
			console.error("Error creating project:", error);
			return fail(500, { form, error: "Failed to create project." });
		}

		return message(form, "Project created successfully!");
	}
}