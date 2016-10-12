/*

 Copyright (c) 2013, Ford Motor Company
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following
 disclaimer in the documentation and/or other materials provided with the
 distribution.

 Neither the name of the Ford Motor Company nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SRC_COMPONENTS_APPLICATION_MANAGER_INCLUDE_APPLICATION_MANAGER_COMMANDS_ON_BUTTON_PRESS_NOTIFICATION_H_
#define SRC_COMPONENTS_APPLICATION_MANAGER_INCLUDE_APPLICATION_MANAGER_COMMANDS_ON_BUTTON_PRESS_NOTIFICATION_H_

#include "application_manager/commands/command_notification_impl.h"
#include "application_manager/application.h"
#include "utils/macro.h"

namespace application_manager {

namespace commands {

namespace mobile {

/**
 * @brief OnButtonPressNotification class is used to send notification
 * to mobile device that some button was pressed on HMI.
 **/
class OnButtonPressNotification : public CommandNotificationImpl {
 public:
  /**
   * @brief OnButtonPressNotification class constructor
   *
   * @param message Incoming SmartObject message
   **/
  OnButtonPressNotification(const MessageSharedPtr& message,
                            ApplicationManager& application_manager);

  /**
   * @brief OnButtonEventCommand class destructor
   **/
  virtual ~OnButtonPressNotification();

  /**
   * @brief Execute command
   **/
  virtual void Run();

 private:
  /*
   * @brief Sends button press notification to mobile device
   *
   * @param app Application to receive notification
   */
  void SendButtonPress(ApplicationConstSharedPtr app);

  DISALLOW_COPY_AND_ASSIGN(OnButtonPressNotification);
};

}  // namespace mobile
}  // namespace commands
}  // namespace application_manager

#endif  // SRC_COMPONENTS_APPLICATION_MANAGER_INCLUDE_APPLICATION_MANAGER_COMMANDS_ON_BUTTON_PRESS_NOTIFICATION_H_