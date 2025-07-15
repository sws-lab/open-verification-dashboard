import { z } from 'zod/v4';
import type { $ZodIssue } from 'zod/v4/core';


type result<Schema extends z.ZodSchema<any>> = {
	success: true;
	data: z.infer<Schema>;
} | {
	success: false;
	error: string;
	issues?: $ZodIssue[];
}

export default async function checkApiSchema<Schema extends z.ZodSchema<any>>(request: Request, schema: Schema): Promise<result<Schema>> {
	const json = await request.json().catch(() => {
		return null;
	});
	if (!json) {
		return { 
			success: false,
			error: 'API request json body is missing or invalid'
		};
	}
	const result = schema.safeParse(json);
	if (!result.success) {
		return {
			success: false,
			error: 'Invalid JSON format',
			issues: result.error.issues
		};
	}
	return {
		success: true,
		data: result.data
	};
}