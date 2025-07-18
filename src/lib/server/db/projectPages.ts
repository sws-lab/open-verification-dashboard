import { env } from '$env/dynamic/public';
import { like, sql } from 'drizzle-orm';
import { db } from '.';
import { projects } from './schema';

const page_size = env.PUBLIC_PAGE_SIZE ? parseInt(env.PUBLIC_PAGE_SIZE) : 30;
export async function getProjects(page: number, filter: string = '') {
	let whereClause = sql`1 = 1`;
	if (filter) {
		whereClause = like(projects.name, `%${filter}%`);
	}
	let data = await db
		.select()
		.from(projects)
		.where(whereClause)
		.orderBy(projects.id)
		.limit(page_size)
		.offset((page - 1) * page_size);
	let totalProjects = await db
		.select({ count: sql<number>`COUNT(*)` })
		.from(projects)
		.where(whereClause);
	let totalPages = Math.ceil(totalProjects[0].count / page_size);
	let lastPageCount = totalProjects[0].count % page_size;

	return {
		pages: totalPages,
		lastPageCount: lastPageCount,
		projects: data
	};
}
