// @flow

import {create} from "../../common/utils/EntityUtils"
import {TypeRef} from "../../common/utils/TypeRef"
import type {TypeModel} from "../../common/EntityTypes"

import type {Blob} from "../sys/Blob"
import type {TypeInfo} from "../sys/TypeInfo"

export const BlobReferenceDataDeleteTypeRef: TypeRef<BlobReferenceDataDelete> = new TypeRef("storage", "BlobReferenceDataDelete")
export const _TypeModel: TypeModel = {
	"name": "BlobReferenceDataDelete",
	"since": 1,
	"type": "DATA_TRANSFER_TYPE",
	"id": 101,
	"rootId": "B3N0b3JhZ2UAZQ",
	"versioned": false,
	"encrypted": false,
	"values": {
		"_format": {
			"id": 102,
			"type": "Number",
			"cardinality": "One",
			"final": false,
			"encrypted": false
		},
		"field": {
			"id": 105,
			"type": "String",
			"cardinality": "One",
			"final": false,
			"encrypted": false
		},
		"instanceListElementId": {
			"id": 104,
			"type": "GeneratedId",
			"cardinality": "One",
			"final": false,
			"encrypted": false
		},
		"instanceListId": {
			"id": 103,
			"type": "GeneratedId",
			"cardinality": "One",
			"final": false,
			"encrypted": false
		}
	},
	"associations": {
		"blobs": {
			"id": 107,
			"type": "AGGREGATION",
			"cardinality": "Any",
			"final": true,
			"refType": "Blob",
			"dependency": "sys"
		},
		"type": {
			"id": 106,
			"type": "AGGREGATION",
			"cardinality": "One",
			"final": true,
			"refType": "TypeInfo",
			"dependency": "sys"
		}
	},
	"app": "storage",
	"version": "2"
}

export function createBlobReferenceDataDelete(values?: $Shape<$Exact<BlobReferenceDataDelete>>): BlobReferenceDataDelete {
	return Object.assign(create(_TypeModel, BlobReferenceDataDeleteTypeRef), values)
}

export type BlobReferenceDataDelete = {
	_type: TypeRef<BlobReferenceDataDelete>;

	_format: NumberString;
	field: string;
	instanceListElementId: Id;
	instanceListId: Id;

	blobs: Blob[];
	type: TypeInfo;
}