import { pb } from '$lib/pb.js';
import { createSlug } from '$lib/utils';
import joi from 'joi';

import { json } from '@sveltejs/kit';

import type { Tag } from '$lib/types/Tag.type';

export async function GET({ locals }) {
	const owner = locals.user?.id;

	if (!owner) {
		return json(
			{
				success: false,
				error: 'Unauthorized'
			},
			{
				status: 401
			}
		);
	}

	try {
		const tags = await pb.collection('tags').getFullList({
			filter: `owner="${owner}"`
		});

		return json(
			{ tags },
			{
				status: 200
			}
		);
	} catch (error: any) {
		return json(
			{
				success: false,
				error: error?.message
			},
			{
				status: 500
			}
		);
	}
}

export async function POST({ locals, request }) {
	const owner = locals.user?.id;

	if (!owner) {
		return json(
			{
				success: false,
				error: 'Unauthorized'
			},
			{
				status: 401
			}
		);
	}

	const requestBody = await request.json();

	const validationSchema = joi.object({
		name: joi.string().required()
	});

	const { error } = validationSchema.validate(requestBody);

	if (error) {
		return json(
			{
				success: false,
				error: error.message
			},
			{
				status: 400
			}
		);
	}

	try {
		const tag = (await pb.collection('tags').create({
			name: requestBody.name,
			slug: createSlug(requestBody.name),
			owner
		})) as Tag;

		if (!tag.id) {
			return json(
				{
					success: false,
					error: 'Tag creation failed'
				},
				{
					status: 400
				}
			);
		}

		return json(
			{ tag },
			{
				status: 200
			}
		);
	} catch (error: any) {
		return json(
			{
				success: false,
				error: error?.message
			},
			{
				status: 500
			}
		);
	}
}
