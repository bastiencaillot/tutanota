// @flow

import {create} from "../../common/utils/EntityUtils"
import {TypeRef} from "@tutao/tutanota-utils"
import type {TypeModel} from "../../common/EntityTypes"


export const ReceiveInfoServiceDataTypeRef: TypeRef<ReceiveInfoServiceData> = new TypeRef("tutanota", "ReceiveInfoServiceData")
export const _TypeModel: TypeModel = {
	"name": "ReceiveInfoServiceData",
	"since": 12,
	"type": "DATA_TRANSFER_TYPE",
	"id": 570,
	"rootId": "CHR1dGFub3RhAAI6",
	"versioned": false,
	"encrypted": false,
	"values": {
		"_format": {
			"id": 571,
			"type": "Number",
			"cardinality": "One",
			"final": false,
			"encrypted": false
		},
		"language": {
			"id": 1121,
			"type": "String",
			"cardinality": "One",
			"final": true,
			"encrypted": false
		}
	},
	"associations": {},
	"app": "tutanota",
	"version": "48"
}

export function createReceiveInfoServiceData(values?: $Shape<$Exact<ReceiveInfoServiceData>>): ReceiveInfoServiceData {
	return Object.assign(create(_TypeModel, ReceiveInfoServiceDataTypeRef), values)
}

export type ReceiveInfoServiceData = {
	_type: TypeRef<ReceiveInfoServiceData>;

	_format: NumberString;
	language: string;
}