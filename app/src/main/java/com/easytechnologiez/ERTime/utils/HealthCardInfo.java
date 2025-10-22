package com.easytechnologiez.ERTime.utils;

public class HealthCardInfo
{
    String HealthCardId;
    String UserEmail;
    String CardLink;

    public String getCardLink() {
        return CardLink;
    }

    public String getHealthCardId() {
        return HealthCardId;
    }

    public String getUserEmail() {
        return UserEmail;
    }

    public void setCardLink(String cardLink) {
        CardLink = cardLink;
    }

    public void setHealthCardId(String healthCardId) {
        HealthCardId = healthCardId;
    }

    public void setUserEmail(String userEmail) {
        UserEmail = userEmail;
    }
}
