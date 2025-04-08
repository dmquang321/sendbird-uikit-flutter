// Copyright (c) 2024 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:sendbird_uikit/sendbird_uikit.dart';
import 'package:sendbird_uikit/src/internal/component/base/sbu_base_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_bottom_sheet_menu_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_file_message_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_icon_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_button_component.dart';
import 'package:sendbird_uikit/src/internal/component/basic/sbu_text_component.dart';
import 'package:sendbird_uikit/src/internal/provider/sbu_message_collection_provider.dart';
import 'package:sendbird_uikit/src/internal/resource/sbu_text_styles.dart';

class SBUNotifyParams {
  String? channelName;
  String? channelUrl;
  String? senderName;
  String? message;
  List<int>? members;

  SBUNotifyParams({
    this.channelName,
    this.channelUrl,
    this.senderName,
    this.message,
    this.members,
  });

  factory SBUNotifyParams.fromJson(Map<String, dynamic> json) {
    return SBUNotifyParams(
      channelName: json['channelName'],
      channelUrl: json['channelUrl'],
      senderName: json['senderName'],
      message: json['message'],
      members: json['members'].cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'channelUrl': channelUrl,
      'senderName': senderName,
      'message': message,
      'members': members,
    };
  }
}

class SBUMessageInputComponent extends SBUStatefulComponent {
  final int messageCollectionNo;
  final Color backgroundColor;
  final void Function(SBUNotifyParams)? onSent;

  const SBUMessageInputComponent({
    required this.messageCollectionNo,
    required this.backgroundColor,
    this.onSent,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => SBUMessageInputComponentState();
}

class SBUMessageInputComponentState extends State<SBUMessageInputComponent> {
  final textEditingController = TextEditingController();
  final textFieldFocusNode = FocusNode();

  bool showSendButton = false;
  bool isEditingMessage = false;
  BaseMessage? preEditingMessage;

  @override
  void dispose() {
    textEditingController.dispose();
    textFieldFocusNode.dispose();

    runZonedGuarded(() {
      final collectionProvider = SBUMessageCollectionProvider();
      final collection =
          collectionProvider.getCollection(widget.messageCollectionNo);

      collection?.channel.endTyping();
    }, (error, stack) {
      // TODO: Check error
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<SBUThemeProvider>();
    final theme = themeProvider.theme;
    final isLightTheme = themeProvider.isLight();
    final strings = context.watch<SBUStringProvider>().strings;

    final collectionProvider = SBUMessageCollectionProvider();
    final collection =
        collectionProvider.getCollection(widget.messageCollectionNo)!; // Check

    final editingMessage =
        collectionProvider.getEditingMessage(widget.messageCollectionNo);

    final replyingToMessage =
        collectionProvider.getReplyingToMessage(widget.messageCollectionNo);

    if (editingMessage != null) {
      textFieldFocusNode.requestFocus();

      if (!isEditingMessage) {
        isEditingMessage = true;
      }

      if (preEditingMessage == null ||
          preEditingMessage?.messageId != editingMessage.messageId) {
        textEditingController.text = editingMessage.message;
        preEditingMessage = editingMessage;
      }
    } else {
      if (isEditingMessage) {
        isEditingMessage = false;
        preEditingMessage = null;
        textEditingController.clear();
      }
    }

    if (replyingToMessage != null) {
      textFieldFocusNode.requestFocus();
    }

    final channel = collection.channel;
    final backgroundColor = widget.backgroundColor;

    final amIMuted = widget.amIMuted(channel);
    final amIFrozen = widget.amIFrozen(channel);
    final isDisabled = widget.isDisabled(channel);

    final sender = Container(
      color: backgroundColor,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 12, top: 10, right: 12, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyingToMessage != null)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 6, top: 2, right: 4, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (replyingToMessage.messageType == MessageType.file)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SBUFileMessageIconComponent(
                            iconSize: 32,
                            fileMessage: replyingToMessage as FileMessage,
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SBUTextComponent(
                              text: strings.replyTo(widget.getNickname(
                                  replyingToMessage.sender, strings)),
                              textType: SBUTextType.caption1,
                              textColorType: SBUTextColorType.text01,
                            ),
                            const SizedBox(height: 8),
                            SBUTextComponent(
                              text: (replyingToMessage is FileMessage)
                                  ? replyingToMessage.name ?? ''
                                  : replyingToMessage.message,
                              textType: SBUTextType.caption2,
                              textColorType: SBUTextColorType.text03,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SBUIconButtonComponent(
                        iconButtonSize: 24,
                        icon: SBUIconComponent(
                          iconSize: 16,
                          iconData: SBUIcons.close,
                          iconColor: isLightTheme
                              ? SBUColors.lightThemeTextHighEmphasis
                              : SBUColors.darkThemeTextHighEmphasis,
                        ),
                        onButtonClicked: () {
                          showSendButton = false;
                          textEditingController.clear();
                          textFieldFocusNode.unfocus();
                          SBUMessageCollectionProvider().resetMessageInputMode(
                              widget.messageCollectionNo);

                          runZonedGuarded(() {
                            channel.endTyping();
                          }, (error, stack) {
                            // TODO: Check error
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  widget.canGetFile() == false
                      ? Container()
                      : (isDisabled
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SBUIconComponent(
                                iconSize: 24,
                                iconData: SBUIcons.add,
                                iconColor: isLightTheme
                                    ? SBUColors.lightThemeTextDisabled
                                    : SBUColors.darkThemeTextDisabled,
                              ),
                            )
                          : editingMessage == null
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SBUIconButtonComponent(
                                    iconButtonSize: 32,
                                    icon: SBUIconComponent(
                                      iconSize: 24,
                                      iconData: SBUIcons.add,
                                      iconColor: isLightTheme
                                          ? SBUColors.primaryMain
                                          : SBUColors.primaryLight,
                                    ),
                                    onButtonClicked: () async {
                                      widget.unfocus();
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                        builder: (context) {
                                          return SBUBottomSheetMenuComponent(
                                            iconNames: [
                                              if (widget.canTakePhoto())
                                                SBUIcons.camera,
                                              if (widget.canTakeVideo())
                                                SBUIcons.camera,
                                              if (widget.canChooseMedia())
                                                SBUIcons.photo,
                                              if (widget.canChooseDocument())
                                                SBUIcons.document,
                                            ],
                                            buttonNames: [
                                              if (widget.canTakePhoto())
                                                strings.takePhoto,
                                              if (widget.canTakeVideo())
                                                strings.takeVideo,
                                              if (widget.canChooseMedia())
                                                strings.gallery,
                                              if (widget.canChooseDocument())
                                                strings.document,
                                            ],
                                            onButtonClicked:
                                                (buttonName) async {
                                              FileInfo? fileInfo;
                                              if (buttonName ==
                                                  strings.takePhoto) {
                                                fileInfo = await SendbirdUIKit()
                                                    .takePhoto!();
                                              } else if (buttonName ==
                                                  strings.takeVideo) {
                                                fileInfo = await SendbirdUIKit()
                                                    .takeVideo!();
                                              } else if (buttonName ==
                                                  strings.gallery) {
                                                fileInfo = await SendbirdUIKit()
                                                    .chooseMedia!();
                                              } else if (buttonName ==
                                                  strings.document) {
                                                fileInfo = await SendbirdUIKit()
                                                    .chooseDocument!();
                                              }

                                              if (fileInfo != null) {
                                                try {
                                                  if (kIsWeb) {
                                                    if (fileInfo.fileBytes !=
                                                        null) {
                                                      channel.sendFileMessage(
                                                        FileMessageCreateParams
                                                            .withFileBytes(
                                                          fileInfo.fileBytes!,
                                                          fileName:
                                                              fileInfo.fileName,
                                                          replyToChannel:
                                                              (replyingToMessage !=
                                                                  null),
                                                          parentMessageId:
                                                              replyingToMessage
                                                                  ?.messageId,
                                                        )..thumbnailSizes = [
                                                            widget
                                                                .getThumbnailSize()
                                                          ],
                                                      );
                                                    }
                                                  } else {
                                                    if (fileInfo.file != null) {
                                                      channel.sendFileMessage(
                                                        FileMessageCreateParams
                                                            .withFile(
                                                          fileInfo.file!,
                                                          fileName:
                                                              fileInfo.fileName,
                                                          replyToChannel:
                                                              (replyingToMessage !=
                                                                  null),
                                                          parentMessageId:
                                                              replyingToMessage
                                                                  ?.messageId,
                                                        )..thumbnailSizes = [
                                                            widget
                                                                .getThumbnailSize()
                                                          ],
                                                      );

                                                      handleOnSent(
                                                        channel,
                                                        'Sent an attachment',
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (e
                                                      is FileSizeLimitExceededException) {
                                                    final uploadSizeLimit =
                                                        SendbirdChat
                                                                .getAppInfo()
                                                            ?.uploadSizeLimit;
                                                    if (uploadSizeLimit !=
                                                        null) {
                                                      widget.showToast(
                                                        isLightTheme:
                                                            isLightTheme,
                                                        text: strings
                                                            .theMaximumSizePerFileIsMB(
                                                                uploadSizeLimit
                                                                    .toString()),
                                                        isError: true,
                                                      );
                                                    }
                                                  } else {
                                                    // TODO: Check error
                                                  }
                                                } finally {
                                                  SBUMessageCollectionProvider()
                                                      .resetMessageInputMode(widget
                                                          .messageCollectionNo);
                                                }
                                              }
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                )
                              : Container()),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isLightTheme
                            ? SBUColors.background100
                            : SBUColors.background400,
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: 16, top: 8, right: 16, bottom: 8),
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: amIFrozen
                              ? strings.chatIsUnavailableInThisChannel
                              : (amIMuted
                                  ? strings.youAreMuted
                                  : (replyingToMessage != null
                                      ? strings.replyToMessage
                                      : strings.enterMessage)),
                          hintStyle: SBUTextStyles.getTextStyle(
                            theme: theme,
                            textType: SBUTextType.body3,
                            textColorType: SBUTextColorType.text03,
                          ),
                        ),
                        enabled: !isDisabled,
                        style: SBUTextStyles.getTextStyle(
                          theme: theme,
                          textType: SBUTextType.body3,
                          textColorType: SBUTextColorType.text01,
                        ),
                        cursorWidth: 1,
                        cursorHeight: 20,
                        cursorColor: isLightTheme
                            ? SBUColors.primaryMain
                            : SBUColors.primaryLight,
                        minLines: 1,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        focusNode: textFieldFocusNode,
                        onChanged: (text) {
                          if (editingMessage == null) {
                            if (showSendButton != text.isNotEmpty) {
                              if (mounted) {
                                setState(() {
                                  showSendButton = text.isNotEmpty;
                                });
                              }
                            }
                          }

                          runZonedGuarded(() {
                            if (text.isNotEmpty) {
                              channel.startTyping();
                            } else {
                              channel.endTyping();
                            }
                          }, (error, stack) {
                            // TODO: Check error
                          });
                        },
                      ),
                    ),
                  ),
                  // Fix a bug like `ㄱㅏ` on web temporarily.
                  if (kIsWeb && (!showSendButton || editingMessage != null))
                    const SizedBox(width: 40),
                  if (showSendButton && editingMessage == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SBUIconButtonComponent(
                        iconButtonSize: 32,
                        icon: SBUIconComponent(
                          iconSize: 24,
                          iconData: SBUIcons.send,
                          iconColor: isLightTheme
                              ? SBUColors.primaryMain
                              : SBUColors.primaryLight,
                        ),
                        onButtonClicked: () {
                          if (textEditingController.text.isNotEmpty) {
                            setState(() {
                              showSendButton = false;
                            });

                            channel.sendUserMessage(
                              UserMessageCreateParams(
                                message: textEditingController.text,
                                replyToChannel: (replyingToMessage != null),
                                parentMessageId: replyingToMessage?.messageId,
                              ),
                              handler: (message, e) {
                                // TODO: Check error
                              },
                            );

                            handleOnSent(
                              channel,
                              textEditingController.text,
                            );
                            textEditingController.clear();
                            SBUMessageCollectionProvider()
                                .resetMessageInputMode(
                                    widget.messageCollectionNo);

                            runZonedGuarded(() {
                              channel.endTyping();
                            }, (error, stack) {
                              // TODO: Check error
                            });
                          }
                        },
                      ),
                    ),
                ],
              ),
              if (editingMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SBUTextButtonComponent(
                        height: 32,
                        text: SBUTextComponent(
                          text: strings.cancel,
                          textType: SBUTextType.button,
                          textColorType: SBUTextColorType.primary,
                        ),
                        onButtonClicked: () {
                          showSendButton = false;
                          textEditingController.clear();
                          textFieldFocusNode.unfocus();
                          SBUMessageCollectionProvider().resetMessageInputMode(
                              widget.messageCollectionNo);

                          runZonedGuarded(() {
                            channel.endTyping();
                          }, (error, stack) {
                            // TODO: Check error
                          });
                        },
                        padding: const EdgeInsets.all(8),
                      ),
                      SBUTextButtonComponent(
                        height: 32,
                        backgroundColor: isLightTheme
                            ? SBUColors.primaryMain
                            : SBUColors.primaryLight,
                        text: SBUTextComponent(
                          text: strings.save,
                          textType: SBUTextType.button,
                          textColorType: SBUTextColorType.message,
                        ),
                        onButtonClicked: () async {
                          runZonedGuarded(() async {
                            await channel.updateUserMessage(
                              editingMessage.messageId,
                              UserMessageUpdateParams(
                                message: textEditingController.text,
                              ),
                            );

                            showSendButton = false;
                            textEditingController.clear();
                            textFieldFocusNode.unfocus();
                            SBUMessageCollectionProvider()
                                .resetMessageInputMode(
                                    widget.messageCollectionNo);
                          }, (error, stack) {
                            // TODO: Check error
                          });

                          runZonedGuarded(() {
                            channel.endTyping();
                          }, (error, stack) {
                            // TODO: Check error
                          });
                        },
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return sender;
  }

  void handleOnSent(GroupChannel channel, String messsage) {
    final currentUser = channel.members.firstWhereOrNull(
      (e) => e.userId == SendbirdChat.currentUser?.userId,
    );

    final listTeamMember = channel.members;
    listTeamMember.remove(currentUser);

    widget.onSent!(
      SBUNotifyParams(
        channelName: channel.name,
        channelUrl: channel.channelUrl,
        senderName: currentUser?.nickname,
        message: messsage,
        members: listTeamMember
            .map((e) => int.tryParse(e.userId.split('_').last) ?? 0)
            .toList(),
      ),
    );
  }
}
