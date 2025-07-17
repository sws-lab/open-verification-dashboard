import { env } from "$env/dynamic/public";
import { and, eq, like, sql } from "drizzle-orm";
import { db } from ".";
import { proofObligation } from "./schema";

const page_size = env.PUBLIC_PAGE_SIZE ? parseInt(env.PUBLIC_PAGE_SIZE) : 30;
export async function getProofObligation(page: number, projectId: number, revision: number, filter: string = "") {
	let filterClause = sql`1 = 1`;
	if (filter) {
		filterClause = like(proofObligation.name, `%${filter}%`)
	}

	const whereClause = and(
		eq(proofObligation.projectId, projectId),
		eq(proofObligation.projectRevision, revision),
		filterClause
	)

	let data = await db.select({
		id: proofObligation.id,
		name: proofObligation.name,
		safe: proofObligation.safe,
		warning: proofObligation.warning,
		error: proofObligation.error,
		uploadDate: proofObligation.uploadDate,
	})
		.from(proofObligation)
		.where(whereClause)
		.orderBy(proofObligation.id)
		.limit(page_size)
		.offset((page - 1) * page_size);
	let proofObligationsCount = await db.select({ count: sql<number>`COUNT(*)` })
		.from(proofObligation)
		.where(whereClause);
	let totalPages = Math.ceil(proofObligationsCount[0].count / page_size);
	let lastPageCount = proofObligationsCount[0].count % page_size;

	return {
		totalPages,
		lastPageCount,
		proofObligationsCount: proofObligationsCount[0].count,
		proofObligation: data
	};
}