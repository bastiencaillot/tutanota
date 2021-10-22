//@flow
import type {Mail} from "../../api/entities/tutanota/Mail";
import type {EntityClient} from "../../api/common/EntityClient";
import {MailBodyTypeRef} from "../../api/entities/tutanota/MailBody";
import {getMailBodyText} from "../../api/common/utils/Utils";
import {FileTypeRef} from "../../api/entities/tutanota/File";
import {MailState} from "../../api/common/TutanotaConstants";
import {getLetId} from "../../api/common/utils/EntityUtils"
import type {HtmlSanitizer} from "../../misc/HtmlSanitizer"
import {promiseMap} from "../../api/common/utils/PromiseUtils"
import type {FileFacade} from "../../api/worker/facades/FileFacade"
import type {MailFacade} from "../../api/worker/facades/MailFacade"

/**
 * Used to pass all downloaded mail stuff to the desktop side to be exported as a file
 * Ideally this would just be {Mail, MailHeaders, MailBody, FileReference[]}
 * but we can't send Dates over to the native side so we may as well just extract everything here
 */
export type MailBundleRecipient = {address: string, name?: string}
export type MailBundle = {
	mailId: IdTuple,
	subject: string,
	body: string,
	sender: MailBundleRecipient,
	to: MailBundleRecipient[],
	cc: MailBundleRecipient[],
	bcc: MailBundleRecipient[],
	replyTo: MailBundleRecipient[],
	isDraft: boolean,
	isRead: boolean,
	sentOn: number, // UNIX timestamp
	receivedOn: number, // UNIX timestamp,
	headers: ?string,
	attachments: DataFile[],
}


/**
 * Downloads the mail body and the attachments for an email, to prepare for exporting
 * @param mail
 * @param entityClient
 * @param sanitizer
 */
export function makeMailBundle(mail: Mail, entityClient: EntityClient, mailFacade: MailFacade, fileFacade: FileFacade, sanitizer: HtmlSanitizer): Promise<MailBundle> {
	const bodyTextPromise = mailFacade.getMailBody(mail)
	                                    .then(body =>
		                                    sanitizer.sanitize(body ?? "", {
			                                    blockExternalContent: false,
			                                    allowRelativeLinks: false,
			                                    usePlaceholderForInlineImages: false
		                                    }).text
	                                    )

	const attachmentsPromise: Promise<Array<DataFile>> =
		promiseMap(mail.attachments, fileId => entityClient.load(FileTypeRef, fileId)
		                                                   .then((file) => fileFacade.downloadFileContent(file)))

	const headersPromise = mailFacade.getHeaders(mail)

	const recipientMapper = addr => ({address: addr.address, name: addr.name})
	return Promise.all([bodyTextPromise, attachmentsPromise, headersPromise])
	              .then(([bodyText, attachments, headers]) => {
		              return {
			              mailId: getLetId(mail),
			              subject: mail.subject,
			              body: bodyText,
			              sender: recipientMapper(mail.sender),
			              to: mail.toRecipients.map(recipientMapper),
			              cc: mail.ccRecipients.map(recipientMapper),
			              bcc: mail.bccRecipients.map(recipientMapper),
			              replyTo: mail.replyTos.map(recipientMapper),
			              isDraft: mail.state === MailState.DRAFT,
			              isRead: !mail.unread,
			              sentOn: mail.sentDate.getTime(),
			              receivedOn: mail.receivedDate.getTime(),
			              headers: headers,
			              attachments: attachments,
		              }
	              })
}