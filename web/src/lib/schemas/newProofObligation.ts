import { z } from 'zod/v4';

const fileSchema = z.file();
fileSchema.mime('application/json');
fileSchema.max(500 * 1024 * 1024); // 500 MB max file size

export const newProofObligationSchema = z.object({
	name: z.string().min(3).max(40),
	proofObligation: fileSchema
});
